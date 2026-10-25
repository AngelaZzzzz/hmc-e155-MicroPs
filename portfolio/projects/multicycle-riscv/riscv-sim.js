// Interactive, cycle-accurate model of the multicycle RISC-V processor in src/top.sv
// and src/maindec.sv. Every signal below mirrors the SystemVerilog one-to-one, and the
// trace format matches a $display testbench so the model can be diffed against RTL.
(function () {
  "use strict";

  // ---------------------------------------------------------------- programs
  const PROGRAMS = {
    riscvtest: {
      name: "riscvtest — E85 Lab 11 self-check",
      words: ["00500113", "00c00193", "ff718393", "0023e233", "0041f2b3", "004282b3",
        "02728663", "0041a233", "00020463", "00000293", "0023a233", "005203b3",
        "402383b3", "0471a223", "05002103", "008001ef", "00100113", "00310133",
        "04202a23"],
      done: (w) => w.adr === 84 && w.data === 71,
      doneMsg: "Simulation succeeded — wrote 71 to address 84",
    },
    fib: {
      name: "Fibonacci — first 10 terms to 0xA0",
      words: ["00000093", "00100113", "00a00193", "0a000213", "02018063", "00122023",
        "002082b3", "00010093", "00028113", "00420213", "fff18193", "fe5ff06f",
        "0c402303", "0e602e23", "0000006f"],
      done: (w) => w.adr === 252,
      doneMsg: "Done — fib(9) = 34 copied to address 0xFC",
    },
  };

  const STATE_NAMES = ["Fetch", "Decode", "MemAdr", "MemRead", "MemWB", "MemWrite",
    "ExecuteR", "ALUWB", "ExecuteI", "JAL", "BEQ"];

  const u32 = (x) => x >>> 0;
  const hex = (x) => u32(x).toString(16).padStart(8, "0");

  // ---------------------------------------------------------------- RTL model
  function nextState(s, op) {
    switch (s) {
      case 0: return 1;
      case 1:
        switch (op) {
          case 0x03: case 0x23: return 2;
          case 0x33: return 6;
          case 0x63: return 10;
          case 0x13: return 8;
          case 0x6f: return 9;
          default: return 0;
        }
      case 2: return op === 0x03 ? 3 : op === 0x23 ? 5 : 0;
      case 3: return 4;
      case 6: case 8: case 9: return 7;
      default: return 0;
    }
  }

  function mainDec(s, op) {
    const c = { RegWrite: 0, ImmSrc: 0, ALUSrcA: 0, ALUSrcB: 0, MemWrite: 0, ResultSrc: 0,
      Branch: 0, ALUOp: 0, AdrSrc: 0, IRWrite: 0, PCUpdate: 0 };
    c.ImmSrc = op === 0x23 ? 1 : op === 0x63 ? 2 : op === 0x6f ? 3 : 0;
    switch (s) {
      case 0: Object.assign(c, { IRWrite: 1, ALUSrcB: 2, ResultSrc: 2, PCUpdate: 1 }); break;
      case 1: Object.assign(c, { ALUSrcA: 1, ALUSrcB: 1 }); break;
      case 2: Object.assign(c, { ALUSrcA: 2, ALUSrcB: 1 }); break;
      case 3: Object.assign(c, { AdrSrc: 1 }); break;
      case 4: Object.assign(c, { ResultSrc: 1, RegWrite: 1 }); break;
      case 5: Object.assign(c, { AdrSrc: 1, MemWrite: 1 }); break;
      case 6: Object.assign(c, { ALUSrcA: 2, ALUOp: 2 }); break;
      case 7: Object.assign(c, { RegWrite: 1 }); break;
      case 8: Object.assign(c, { ALUSrcA: 2, ALUSrcB: 1, ALUOp: 2 }); break;
      case 9: Object.assign(c, { ALUSrcA: 1, ALUSrcB: 2, PCUpdate: 1 }); break;
      case 10: Object.assign(c, { ALUSrcA: 2, ALUOp: 1, Branch: 1 }); break;
    }
    return c;
  }

  function aluDec(opb5, funct3, funct7b5, aluOp) {
    if (aluOp === 0) return 0b000;
    if (aluOp === 1) return 0b001;
    switch (funct3) {
      case 0b000: return (funct7b5 & opb5) ? 0b001 : 0b000;
      case 0b010: return 0b101;
      case 0b110: return 0b011;
      case 0b111: return 0b010;
      default: return 0b000;
    }
  }

  function alu(a, b, ctl) {
    const sum = u32(a + u32(ctl & 1 ? ~b : b) + (ctl & 1));
    let r;
    switch (ctl) {
      case 0b000: case 0b001: r = sum; break;
      case 0b010: r = u32(a & b); break;
      case 0b011: r = u32(a | b); break;
      case 0b101: r = sum >>> 31; break;
      default: r = 0;
    }
    return { result: r, zero: r === 0 ? 1 : 0 };
  }

  function extend(ins, immSrc) {
    const s = ins | 0;
    switch (immSrc) {
      case 0: return u32(s >> 20);
      case 1: return u32(((s >> 25) << 5) | ((ins >>> 7) & 0x1f));
      case 2: return u32(((s >> 31) << 12) | (((ins >>> 7) & 1) << 11) |
        (((ins >>> 25) & 0x3f) << 5) | (((ins >>> 8) & 0xf) << 1));
      default: return u32(((s >> 31) << 20) | (((ins >>> 12) & 0xff) << 12) |
        (((ins >>> 20) & 1) << 11) | (((ins >>> 21) & 0x3ff) << 1));
    }
  }

  const mux3 = (d0, d1, d2, s) => (s & 2 ? d2 : s & 1 ? d1 : d0);
  const memIdx = (a) => (a >>> 2) & 63;

  class CPU {
    constructor(words) { this.load(words); }
    load(words) {
      this.mem = new Uint32Array(64);
      words.forEach((w, i) => { if (i < 64) this.mem[i] = parseInt(w, 16) >>> 0; });
      this.program = this.mem.slice(0, words.length);
      this.rf = new Uint32Array(32);
      this.PC = 0; this.OldPC = 0; this.Instr = 0; this.Data = 0;
      this.A = 0; this.WriteData = 0; this.ALUOut = 0;
      this.state = 0; this.cycle = 0;
      this.lastRegWrite = -1; this.writes = [];
      this.prevState = null;
      this.eval();
    }
    // combinational logic for the current cycle
    eval() {
      const ins = this.Instr, op = ins & 0x7f;
      const c = mainDec(this.state, op);
      const rs1 = (ins >>> 15) & 31, rs2 = (ins >>> 20) & 31, rd = (ins >>> 7) & 31;
      const RD1 = rs1 ? this.rf[rs1] : 0, RD2 = rs2 ? this.rf[rs2] : 0;
      const ImmExt = extend(ins, c.ImmSrc);
      const SrcA = mux3(this.PC, this.OldPC, this.A, c.ALUSrcA);
      const SrcB = mux3(this.WriteData, ImmExt, 4, c.ALUSrcB);
      const ALUControl = aluDec((op >>> 5) & 1, (ins >>> 12) & 7, (ins >>> 30) & 1, c.ALUOp);
      const { result: ALUResult, zero: Zero } = alu(SrcA, SrcB, ALUControl);
      const Result = mux3(this.ALUOut, this.Data, ALUResult, c.ResultSrc);
      const Adr = c.AdrSrc ? Result : this.PC;
      const ReadData = this.mem[memIdx(Adr)];
      const PCWrite = (c.Branch & Zero) | c.PCUpdate;
      this.sig = Object.assign({}, c, { op, rs1, rs2, rd, RD1, RD2, ImmExt, SrcA, SrcB,
        ALUControl, ALUResult, Zero, Result, Adr, ReadData, PCWrite });
      return this.sig;
    }
    traceLine() {
      const s = this.sig;
      return `C ${this.cycle} S ${this.state} PC ${hex(this.PC)} I ${hex(this.Instr)} ` +
        `RW ${s.RegWrite} RD ${s.rd} R ${hex(s.Result)} MW ${s.MemWrite} A ${hex(s.Adr)} WD ${hex(this.WriteData)}`;
    }
  }

  // rising clock edge: every register samples its pre-edge input
  CPU.prototype.tick = function () {
    const s = this.sig;
    const pre = { PC: this.PC, ReadData: s.ReadData, Instr: this.Instr };
    let write = null;
    this.lastRegWrite = -1;
    // x0 reads as 0 in RegFile, so a write to it is never observable
    if (s.RegWrite && s.rd !== 0) { this.rf[s.rd] = s.Result; this.lastRegWrite = s.rd; }
    if (s.MemWrite) {
      this.mem[memIdx(s.Adr)] = this.WriteData;
      write = { cycle: this.cycle, adr: s.Adr, data: this.WriteData };
      this.writes.push(write);
    }
    if (s.PCWrite) this.PC = s.Result;
    if (s.IRWrite) { this.OldPC = pre.PC; this.Instr = pre.ReadData; }
    this.Data = pre.ReadData;
    this.A = s.RD1;
    this.WriteData = s.RD2;
    this.ALUOut = s.ALUResult;
    this.prevState = this.state;
    this.state = nextState(this.state, s.op);
    this.cycle++;
    this.eval();
    return write;
  };

  // ---------------------------------------------------------------- disassembler
  function disasm(w) {
    const op = w & 0x7f, rd = (w >>> 7) & 31, f3 = (w >>> 12) & 7, rs1 = (w >>> 15) & 31,
      rs2 = (w >>> 20) & 31, f7 = w >>> 25;
    const x = (r) => "x" + r;
    const sx = (v) => (v | 0);
    switch (op) {
      case 0x33: {
        const n = { 0: f7 === 0x20 ? "sub" : "add", 7: "and", 6: "or", 2: "slt" }[f3] || "r?";
        return `${n} ${x(rd)}, ${x(rs1)}, ${x(rs2)}`;
      }
      case 0x13: {
        const n = { 0: "addi", 7: "andi", 6: "ori", 2: "slti" }[f3] || "i?";
        return `${n} ${x(rd)}, ${x(rs1)}, ${sx(extend(w, 0))}`;
      }
      case 0x03: return `lw ${x(rd)}, ${sx(extend(w, 0))}(${x(rs1)})`;
      case 0x23: return `sw ${x(rs2)}, ${sx(extend(w, 1))}(${x(rs1)})`;
      case 0x63: return `beq ${x(rs1)}, ${x(rs2)}, ${sx(extend(w, 2))}`;
      case 0x6f: return `jal ${x(rd)}, ${sx(extend(w, 3))}`;
      default: return w === 0 ? "—" : "unsupported";
    }
  }

  // ---------------------------------------------------------------- datapath drawing
  const NS = "http://www.w3.org/2000/svg";
  function el(tag, attrs, parent, text) {
    const e = document.createElementNS(NS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    if (text !== undefined) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  }

  const WIRES = {
    pc_adr: [[106, 235], [122, 235], [122, 220], [140, 220]],
    pc_oldpc: [[106, 235], [122, 235], [122, 95], [350, 95]],
    pc_srca: [[106, 235], [122, 235], [122, 40], [690, 40], [690, 165], [700, 165]],
    adr_mem: [[162, 235], [190, 235]],
    rd_instr: [[310, 235], [350, 235]],
    rd_data: [[310, 235], [330, 235], [330, 315], [350, 315]],
    oldpc_srca: [[390, 95], [680, 95], [680, 190], [700, 190]],
    instr_a1: [[390, 235], [420, 235], [420, 190], [470, 190]],
    instr_a2: [[390, 235], [420, 235], [420, 215], [470, 215]],
    instr_a3: [[390, 235], [420, 235], [420, 260], [470, 260]],
    instr_ext: [[390, 235], [420, 235], [420, 385], [490, 385]],
    rd1_a: [[590, 200], [620, 200]],
    rd2_wd: [[590, 270], [620, 270]],
    a_srca: [[654, 200], [670, 200], [670, 215], [700, 215]],
    wd_srcb: [[654, 270], [672, 270], [672, 275], [700, 275]],
    wd_mem: [[654, 270], [662, 270], [662, 420], [175, 420], [175, 295], [190, 295]],
    imm_srcb: [[580, 385], [680, 385], [680, 300], [700, 300]],
    four_srcb: [[690, 325], [700, 325]],
    srca_alu: [[722, 190], [760, 190]],
    srcb_alu: [[722, 300], [760, 300]],
    alu_aluout: [[810, 245], [850, 245]],
    alu_res: [[810, 245], [830, 245], [830, 335], [915, 335], [915, 280], [930, 280]],
    aluout_res: [[884, 245], [905, 245], [905, 220], [930, 220]],
    data_res: [[390, 315], [400, 315], [400, 350], [920, 350], [920, 250], [930, 250]],
    res_out: [[952, 250], [990, 250], [990, 440]],
    res_pc: [[990, 440], [40, 440], [40, 235], [70, 235]],
    res_adr: [[990, 440], [130, 440], [130, 250], [140, 250]],
    res_wd3: [[990, 440], [450, 440], [450, 300], [470, 300]],
  };
  const DOTS = [[122, 235], [122, 95], [330, 235], [420, 235], [420, 215], [420, 260],
    [662, 270], [830, 245], [990, 440], [450, 440], [130, 440]];

  const RESULT_SRC = { 0: "aluout_res", 1: "data_res", 2: "alu_res" };
  function activeWires(st, sig) {
    const alu = ["srca_alu", "srcb_alu"];
    const res = (dst) => [RESULT_SRC[sig.ResultSrc], "res_out", dst];
    switch (st) {
      case 0: return ["pc_adr", "adr_mem", "rd_instr", "pc_oldpc", "pc_srca", "four_srcb",
        ...alu, ...res("res_pc")];
      case 1: return ["instr_a1", "instr_a2", "rd1_a", "rd2_wd", "instr_ext", "oldpc_srca",
        "imm_srcb", ...alu, "alu_aluout"];
      case 2: case 8: return ["a_srca", "imm_srcb", "instr_ext", ...alu, "alu_aluout"];
      case 3: return [...res("res_adr"), "adr_mem", "rd_data"];
      case 4: case 7: return [...res("res_wd3"), "instr_a3"];
      case 5: return [...res("res_adr"), "adr_mem", "wd_mem"];
      case 6: return ["a_srca", "wd_srcb", ...alu, "alu_aluout"];
      case 9: return ["oldpc_srca", "four_srcb", ...alu, "alu_aluout", ...res("res_pc")];
      case 10: return ["a_srca", "wd_srcb", ...alu,
        ...(sig.Zero ? res("res_pc") : [])];
    }
    return [];
  }

  function muxPts(x, y, w, h) {
    return `${x},${y} ${x + w},${y + 10} ${x + w},${y + h - 10} ${x},${y + h}`;
  }

  function buildDatapath(svg) {
    svg.setAttribute("viewBox", "0 0 1030 470");
    const gWires = el("g", { class: "rv-wires" }, svg);
    const gHot = el("g", { class: "rv-hot" }, svg);
    const wireEls = {};
    for (const id in WIRES) {
      const pts = WIRES[id].map((p) => p.join(",")).join(" ");
      el("polyline", { points: pts, class: "rv-wire" }, gWires);
      wireEls[id] = el("polyline", { points: pts, class: "rv-wire-hot" }, gHot);
    }
    for (const [x, y] of DOTS) el("circle", { cx: x, cy: y, r: 2.6, class: "rv-dot" }, gWires);

    const gParts = el("g", {}, svg);
    const parts = {};
    const box = (id, x, y, w, h, label, sub) => {
      const g = el("g", { class: "rv-part" }, gParts);
      el("rect", { x, y, width: w, height: h, rx: 4 }, g);
      el("text", { x: x + w / 2, y: y + h / 2 + (sub ? -3 : 4), class: "rv-label" }, g, label);
      if (sub) el("text", { x: x + w / 2, y: y + h / 2 + 11, class: "rv-sublabel" }, g, sub);
      parts[id] = g;
      return g;
    };
    const mux = (id, x, y, w, h, ins) => {
      const g = el("g", { class: "rv-part rv-mux" }, gParts);
      el("polygon", { points: muxPts(x, y, w, h) }, g);
      ins.forEach(([yy, t]) => el("text", { x: x + 3, y: yy + 3, class: "rv-pin" }, g, t));
      parts[id] = g;
    };

    box("pc", 70, 200, 36, 70, "PC");
    mux("adrmux", 140, 205, 22, 60, [[220, "0"], [250, "1"]]);
    const memG = box("mem", 190, 180, 120, 140, "Instr / Data", "Memory");
    el("text", { x: 196, y: 239, class: "rv-pin rv-pin-l" }, memG, "A");
    el("text", { x: 196, y: 299, class: "rv-pin rv-pin-l" }, memG, "WD");
    el("text", { x: 304, y: 239, class: "rv-pin rv-pin-r" }, memG, "RD");
    box("oldpc", 350, 70, 40, 50, "OldPC");
    box("instr", 350, 200, 40, 70, "Instr");
    box("data", 350, 290, 40, 50, "Data");
    const rfG = box("rf", 470, 170, 120, 150, "Register", "File");
    [[190, "A1"], [215, "A2"], [260, "A3"], [300, "WD3"]].forEach(([y, t]) =>
      el("text", { x: 476, y: y + 4, class: "rv-pin rv-pin-l" }, rfG, t));
    [[200, "RD1"], [270, "RD2"]].forEach(([y, t]) =>
      el("text", { x: 584, y: y + 4, class: "rv-pin rv-pin-r" }, rfG, t));
    box("ext", 490, 365, 90, 40, "Extend");
    box("a", 620, 180, 34, 40, "A");
    box("wd", 620, 250, 34, 40, "WD");
    mux("srca", 700, 150, 22, 80, [[165, "0"], [190, "1"], [215, "2"]]);
    mux("srcb", 700, 260, 22, 80, [[275, "0"], [300, "1"], [325, "2"]]);
    el("text", { x: 686, y: 329, class: "rv-pin rv-pin-r" }, gParts, "4");
    const aluG = el("g", { class: "rv-part" }, gParts);
    el("polygon", { points: "760,160 810,190 810,300 760,330 760,262 772,245 760,228" }, aluG);
    el("text", { x: 790, y: 249, class: "rv-label" }, aluG, "ALU");
    parts.alu = aluG;
    box("aluout", 850, 220, 34, 50, "ALU", "Out");
    mux("resmux", 930, 205, 22, 90, [[220, "0"], [250, "1"], [280, "2"]]);

    // bit-field hints
    [[426, 186, "rs1"], [426, 211, "rs2"], [426, 256, "rd"], [426, 381, "31:7"]].forEach(([x, y, t]) =>
      el("text", { x, y, class: "rv-hint" }, gParts, t));
    el("text", { x: 500, y: 455, class: "rv-hint" }, gParts, "Result");

    // control-signal tags
    const ctl = {};
    const tag = (id, x, y, anchor = "middle") => {
      ctl[id] = el("text", { x, y, class: "rv-ctl", "text-anchor": anchor }, gParts, id);
    };
    tag("PCWrite", 88, 193);
    tag("AdrSrc", 151, 198);
    tag("MemWrite", 250, 173);
    tag("IRWrite", 370, 63);
    tag("RegWrite", 530, 163);
    tag("ImmSrc", 535, 418);
    tag("ALUSrcA", 711, 143);
    tag("ALUSrcB", 711, 254);
    tag("ALUControl", 785, 344);
    tag("Zero", 816, 206, "start");
    tag("ResultSrc", 941, 198);

    // live values
    const val = {};
    const v = (id, x, y, anchor = "middle") => {
      val[id] = el("text", { x, y, class: "rv-val", "text-anchor": anchor }, gParts, "");
    };
    v("PC", 88, 284);
    v("OldPC", 370, 133);
    v("Instr", 370, 284);
    v("Data", 370, 365);
    v("A", 637, 233);
    v("WriteData", 637, 303);
    v("ImmExt", 630, 380);
    v("SrcA", 741, 184);
    v("SrcB", 741, 294);
    v("ALUResult", 830, 238, "middle");
    v("ALUOut", 867, 284);
    v("Result", 970, 462);
    v("Adr", 176, 229);
    v("ReadData", 331, 224);

    return { wireEls, parts, ctl, val };
  }

  // ---------------------------------------------------------------- FSM drawing
  const FSM_POS = { 0: [320, 28], 1: [320, 92], 2: [70, 162], 6: [195, 162], 8: [320, 162],
    9: [445, 162], 10: [570, 162], 3: [60, 232], 5: [180, 232], 7: [320, 232], 4: [60, 300] };
  const FSM_EDGES = [[0, 1, ""], [1, 2, "lw/sw"], [1, 6, "R"], [1, 8, "I"], [1, 9, "jal"],
    [1, 10, "beq"], [2, 3, "lw"], [2, 5, "sw"], [3, 4, ""], [6, 7, ""], [8, 7, ""], [9, 7, ""]];

  function buildFSM(svg) {
    svg.setAttribute("viewBox", "0 0 640 330");
    const defs = el("defs", {}, svg);
    const m = el("marker", { id: "rv-arrow", viewBox: "0 0 10 10", refX: 9, refY: 5,
      markerWidth: 6, markerHeight: 6, orient: "auto-start-reverse" }, defs);
    el("path", { d: "M0,0 L10,5 L0,10 z", class: "rv-arrowhead" }, m);
    const edges = {};
    for (const [a, b, label] of FSM_EDGES) {
      const [x1, y1] = FSM_POS[a], [x2, y2] = FSM_POS[b];
      const line = el("line", { x1, y1: y1 + 15, x2, y2: y2 - 17, class: "rv-edge",
        "marker-end": "url(#rv-arrow)" }, svg);
      edges[`${a}-${b}`] = line;
      if (label) el("text", { x: (x1 + x2) / 2 + (x2 >= x1 ? 6 : -6), y: (y1 + y2) / 2 + 2,
        class: "rv-edge-label", "text-anchor": x2 >= x1 ? "start" : "end" }, svg, label);
    }
    const nodes = {};
    for (const s in FSM_POS) {
      const [x, y] = FSM_POS[s];
      const g = el("g", { class: "rv-node" }, svg);
      el("rect", { x: x - 54, y: y - 16, width: 108, height: 32, rx: 16 }, g);
      el("text", { x, y: y + 4, class: "rv-node-label" }, g, `S${s} ${STATE_NAMES[s]}`);
      nodes[s] = g;
    }
    el("text", { x: 630, y: 318, class: "rv-edge-label", "text-anchor": "end" }, svg,
      "S4, S5, S7 and S10 return to S0 Fetch");
    return { nodes, edges };
  }

  // ---------------------------------------------------------------- UI
  function init(root) {
    const $ = (sel) => root.querySelector(sel);
    const dp = buildDatapath($(".rv-datapath"));
    const fsm = buildFSM($(".rv-fsm"));
    const cpu = new CPU(PROGRAMS.riscvtest.words);
    let prog = PROGRAMS.riscvtest;
    let timer = null, done = false;

    const regGrid = $(".rv-regs");
    const regCells = [];
    for (let i = 0; i < 32; i++) {
      const d = document.createElement("div");
      d.className = "rv-reg";
      d.innerHTML = `<span class="rv-reg-name">x${i}</span><span class="rv-reg-val"></span>`;
      regGrid.appendChild(d);
      regCells.push(d);
    }

    function renderProgram() {
      const tbody = $(".rv-program tbody");
      tbody.innerHTML = "";
      cpu.program.forEach((w, i) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${(i * 4).toString(16).padStart(2, "0")}</td><td>${hex(w)}</td><td>${disasm(w)}</td>`;
        tbody.appendChild(tr);
      });
    }

    function render() {
      const s = cpu.sig, st = cpu.state;
      const on = new Set(activeWires(st, s));
      for (const id in dp.wireEls) dp.wireEls[id].classList.toggle("on", on.has(id));

      const busy = {
        0: ["pc", "adrmux", "mem", "instr", "oldpc", "srca", "srcb", "alu", "resmux"],
        1: ["instr", "rf", "ext", "a", "wd", "srca", "srcb", "alu", "aluout"],
        2: ["a", "ext", "srca", "srcb", "alu", "aluout"],
        3: ["aluout", "resmux", "adrmux", "mem", "data"],
        4: ["data", "resmux", "rf"],
        5: ["aluout", "resmux", "adrmux", "mem", "wd"],
        6: ["a", "wd", "srca", "srcb", "alu", "aluout"],
        7: ["aluout", "resmux", "rf"],
        8: ["a", "ext", "srca", "srcb", "alu", "aluout"],
        9: ["oldpc", "srca", "srcb", "alu", "aluout", "resmux", "pc"],
        10: ["a", "wd", "srca", "srcb", "alu", "aluout", "resmux"],
      }[st];
      const writing = new Set();
      if (s.PCWrite) writing.add("pc");
      if (s.IRWrite) { writing.add("instr"); writing.add("oldpc"); }
      if (s.RegWrite) writing.add("rf");
      if (s.MemWrite) writing.add("mem");
      for (const id in dp.parts) {
        dp.parts[id].classList.toggle("on", busy.includes(id));
        dp.parts[id].classList.toggle("write", writing.has(id));
      }

      const ctlVals = { PCWrite: s.PCWrite, AdrSrc: s.AdrSrc, MemWrite: s.MemWrite,
        IRWrite: s.IRWrite, RegWrite: s.RegWrite, ImmSrc: s.ImmSrc, ALUSrcA: s.ALUSrcA,
        ALUSrcB: s.ALUSrcB, ALUControl: s.ALUControl, Zero: s.Zero, ResultSrc: s.ResultSrc };
      const width = { ImmSrc: 2, ALUSrcA: 2, ALUSrcB: 2, ResultSrc: 2, ALUControl: 3 };
      for (const k in ctlVals) {
        const w = width[k];
        const valStr = w ? ctlVals[k].toString(2).padStart(w, "0") : String(ctlVals[k]);
        dp.ctl[k].textContent = `${k}=${valStr}`;
        const relevant = w ? true : ctlVals[k] === 1;
        dp.ctl[k].classList.toggle("on", relevant && (w ? isUsed(k, st) : true));
      }

      const short = (x) => "0x" + u32(x).toString(16);
      const vals = { PC: cpu.PC, OldPC: cpu.OldPC, Instr: cpu.Instr, Data: cpu.Data, A: cpu.A,
        WriteData: cpu.WriteData, ImmExt: s.ImmExt, SrcA: s.SrcA, SrcB: s.SrcB,
        ALUResult: s.ALUResult, ALUOut: cpu.ALUOut, Result: s.Result, Adr: s.Adr,
        ReadData: s.ReadData };
      for (const k in vals) dp.val[k].textContent = k === "Instr" || k === "ReadData" ? hex(vals[k]) : short(vals[k]);

      for (const n in fsm.nodes) fsm.nodes[n].classList.toggle("on", Number(n) === st);
      for (const e in fsm.edges) fsm.edges[e].classList.toggle("on", e === `${cpu.prevState}-${st}`);

      $(".rv-cycle").textContent = cpu.cycle;
      $(".rv-state").textContent = `S${st} · ${STATE_NAMES[st]}`;
      const curAdr = st === 0 ? cpu.PC : cpu.OldPC;
      $(".rv-instr").textContent = st === 0 ? `fetching 0x${curAdr.toString(16)}` : disasm(cpu.Instr);

      const rows = root.querySelectorAll(".rv-program tbody tr");
      rows.forEach((r, i) => r.classList.toggle("on", i * 4 === curAdr));
      const cur = rows[curAdr / 4], wrap = $(".rv-program-wrap");
      if (cur) {
        const top = cur.offsetTop - wrap.clientHeight / 2;
        wrap.scrollTop = Math.max(0, top);
      }

      regCells.forEach((d, i) => {
        d.querySelector(".rv-reg-val").textContent = cpu.rf[i] === 0 ? "0" : "0x" + cpu.rf[i].toString(16);
        d.classList.toggle("nz", i !== 0 && cpu.rf[i] !== 0);
        d.classList.toggle("just", i === cpu.lastRegWrite);
      });

      const log = $(".rv-writes");
      log.innerHTML = cpu.writes.length ? cpu.writes.map((w) =>
        `<li><span>cycle ${w.cycle}</span> mem[0x${w.adr.toString(16)}] ← ${w.data} <span>(0x${w.data.toString(16)})</span></li>`).join("")
        : `<li class="rv-empty">No stores yet</li>`;

      const banner = $(".rv-banner");
      banner.hidden = !done;
      banner.textContent = done ? "✓ " + prog.doneMsg : "";
    }

    function isUsed(k, st) {
      const aluStates = [0, 1, 2, 6, 8, 9, 10];
      if (k === "ALUSrcA" || k === "ALUSrcB" || k === "ALUControl") return aluStates.includes(st);
      if (k === "ResultSrc") return [0, 3, 4, 5, 7, 9, 10].includes(st);
      if (k === "ImmSrc") return [1, 2, 8].includes(st);
      return true;
    }

    function step() {
      if (done) return false;
      const w = cpu.tick();
      if (w && prog.done && prog.done(w)) { done = true; stop(); }
      return true;
    }
    function stepInstr() {
      if (done) return;
      let n = 0;
      do { step(); n++; } while (cpu.state !== 0 && n < 10 && !done);
      render();
    }
    function stop() {
      clearInterval(timer); timer = null;
      $(".rv-run").textContent = "▶ Run";
    }
    function run() {
      if (timer) { stop(); return; }
      if (done) return;
      $(".rv-run").textContent = "❚❚ Pause";
      const rate = Number($(".rv-speed").value);
      timer = setInterval(() => { step(); render(); }, 1000 / rate);
    }
    function reset(words) {
      stop(); done = false;
      cpu.load(words || prog.words);
      renderProgram(); render();
    }

    $(".rv-step").addEventListener("click", () => { stop(); step(); render(); });
    $(".rv-stepi").addEventListener("click", () => { stop(); stepInstr(); });
    $(".rv-run").addEventListener("click", run);
    $(".rv-reset").addEventListener("click", () => reset());
    $(".rv-speed").addEventListener("input", () => { if (timer) { stop(); run(); } });
    $(".rv-select").addEventListener("change", (e) => {
      const key = e.target.value;
      $(".rv-custom").hidden = key !== "custom";
      if (key === "custom") return;
      prog = PROGRAMS[key];
      reset(prog.words);
    });
    $(".rv-load").addEventListener("click", () => {
      const words = ($(".rv-custom textarea").value.match(/[0-9a-fA-F]{1,8}/g) || []).slice(0, 64);
      if (!words.length) return;
      prog = { name: "custom", words, done: null, doneMsg: "" };
      reset(words);
    });

    renderProgram(); render();

    // Deep link: #rv-cycle=N opens the simulator N cycles in (#rv-fib-cycle=N for the Fibonacci program)
    const deep = location.hash.match(/^#rv-(fib-)?cycle=(\d+)$/);
    if (deep) {
      if (deep[1]) { $(".rv-select").value = "fib"; prog = PROGRAMS.fib; reset(prog.words); }
      for (let i = 0; i < Math.min(Number(deep[2]), 5000); i++) step();
      render();
    }

    // Self-test hook: load with #rv-selftest to dump a trace comparable to the RTL testbench
    if (location.hash === "#rv-selftest") {
      const out = [];
      for (const key of ["riscvtest", "fib"]) {
        const t = new CPU(PROGRAMS[key].words);
        out.push("== " + key);
        for (let i = 0; i < 400; i++) { out.push(t.traceLine()); t.tick(); }
      }
      const pre = document.createElement("pre");
      pre.id = "rv-selftest-out";
      pre.textContent = out.join("\n");
      document.body.appendChild(pre);
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".rv-sim").forEach(init);
  });
})();

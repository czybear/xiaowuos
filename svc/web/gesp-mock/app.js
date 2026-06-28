const state = {
  view: "landing",
  selectedSystem: "code",
  account: null,
  language: "cpp",
  level: "1",
  durationMinutes: 45,
  remainingSeconds: 45 * 60,
  timerId: null,
  currentIndex: 0,
  answers: {},
  marked: {},
  lastResult: null,
  currentCodeProblem: "choice",
  scratchIndex: 0,
  submissions: [],
  codeScores: {},
  submissionSeq: 891300,
};

const codeObjectiveSamples = {
  choice: [
    {
      prompt: "下面 C++ 代码执行后其输出是( )。",
      code: "for (int i=0; i<10; i++)\n    printf(\"%d\",i);",
      options: ["123456789", "012345678910", "0123456789", "12345678910"],
    },
    {
      prompt: "C++ 语句 cout << (3 + 3 % 3 * 2 - 1) 执行后输出的值是（ ）。",
      options: ["4", "2", "-1", "56"],
    },
    {
      prompt: "下面 C++ 代码的相关说法中，正确的是( )。",
      code: "int tnt;\nfor (int i=0; i<10; i++)\n    tnt += i;\ncout << tnt;",
      options: ["上述代码执行后其输出相当于求1-10的和（不包含10）", "上述代码执行后其输出相当于求1-10的和（包含10）", "上述代码执行后将输出不确定的值", "上述代码执行后其输出相当于求0-10的和（不包含10）"],
    },
    {
      prompt: "诺贝尔物理学奖曾颁给两位计算机科学家，他们的主要研究方向是（ ）。",
      options: ["人工智能", "天体物理", "量子理论", "流体力学"],
    },
    {
      prompt: "计算机系统中存储的基本单位用 B 表示，它代表的是（ ）。",
      options: ["Byte", "Block", "Bit", "Bulk"],
    },
  ],
  judge: [
    { prompt: "C++ 中 for 循环可以用于固定次数的重复执行。", options: ["正确", "错误"] },
    { prompt: "变量在使用前不需要声明类型。", options: ["正确", "错误"] },
    { prompt: "break 语句可以提前结束循环。", options: ["正确", "错误"] },
    { prompt: "数组下标通常从 1 开始。", options: ["正确", "错误"] },
    { prompt: "取模运算 % 常用于判断奇偶。", options: ["正确", "错误"] },
  ],
};

const codeProgramSamples = {
  program1: {
    title: "寻找数字",
    score: 25,
    body: "小杨有一个正整数 a，小杨想知道是否存在一个正整数 b 满足 a = b^4。",
    input: "第一行包含一个正整数 t，代表测试数据组数。\n对于每组测试数据，第一行包含一个正整数代表 a。",
    output: "对于每组测试数据，如果存在满足条件的正整数 b，则输出 b，否则输出 -1。",
    sampleIn: "3\n16\n81\n10",
    sampleOut: "2\n3\n-1",
    history: [
      ["891292", "等待评测", "0", "16:32:32 有效递交"],
      ["889696", "答案正确", "25", "13:54:02"],
      ["889674", "超过时间限制", "2.5", "13:52:53"],
      ["889630", "答案错误", "0", "13:48:29"],
      ["889613", "编译错误", "0", "13:47:04"],
    ],
  },
  program2: {
    title: "数字处理",
    score: 25,
    body: "给定若干正整数，按题目要求完成统计与输出。",
    input: "第一行包含正整数 n，接下来一行包含 n 个整数。",
    output: "输出处理后的结果。",
    sampleIn: "5\n1 2 3 4 5",
    sampleOut: "15",
    history: [
      ["891101", "等待评测", "0", "16:12:32"],
      ["889701", "答案错误", "10", "13:58:02"],
      ["889620", "编译错误", "0", "13:47:38"],
    ],
  },
};

const questionBank = [
  {
    id: "q1",
    type: "single",
    title: "变量与输出",
    score: 10,
    body: "执行下面语句后，屏幕上输出的结果是：\n\nx = 3\nprint(x + 2)",
    choices: ["3", "5", "x + 2", "程序报错"],
    answer: "B",
    tags: ["python"],
  },
  {
    id: "q2",
    type: "single",
    title: "循环次数",
    score: 10,
    body: "下面循环体会执行几次？\n\nfor (int i = 0; i < 5; i++) {\n  cout << i;\n}",
    choices: ["4 次", "5 次", "6 次", "无法确定"],
    answer: "B",
    tags: ["cpp"],
  },
  {
    id: "q3",
    type: "judge",
    title: "条件判断",
    score: 10,
    body: "在程序中，if 语句通常用于根据条件选择不同的执行路径。",
    choices: ["正确", "错误"],
    answer: "A",
    tags: ["all"],
  },
  {
    id: "q4",
    type: "single",
    title: "算法理解",
    score: 10,
    body: "如果要找出一组数中的最大值，通常需要把每个数都和当前最大值比较。这个过程体现了哪类思路？",
    choices: ["枚举/遍历", "加密", "压缩", "随机猜测"],
    answer: "A",
    tags: ["all"],
  },
  {
    id: "q5",
    type: "program",
    title: "编程题：求和",
    score: 60,
    body: "输入一个正整数 n，输出 1 到 n 的整数和。\n\n输入样例：\n5\n\n输出样例：\n15",
    template: {
      cpp: "#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n    // 在这里完成求和\n    return 0;\n}\n",
      python: "n = int(input())\n# 在这里完成求和\n",
    },
    keywords: {
      cpp: ["for", "sum", "cout"],
      python: ["for", "sum", "print"],
    },
    tags: ["cpp", "python"],
  },
  {
    id: "s1",
    type: "scratch",
    title: "图形化题：角色移动",
    score: 40,
    body: "点击开始后，让角色重复移动 4 次，每次移动 10 步，最后说“完成”。",
    answer: "当开始被点击 → 重复执行 → 移动 10 步 → 说出结果",
    keywords: ["当开始", "重复", "移动", "说"],
    tags: ["scratch"],
  },
  {
    id: "s2",
    type: "scratch",
    title: "图形化题：条件判断",
    score: 60,
    body: "设计一个程序：如果得分大于 80，就让角色说“优秀”，否则说“继续努力”。",
    answer: "当开始被点击 → 如果 条件 → 说出结果",
    keywords: ["如果", "80", "优秀", "继续"],
    tags: ["scratch"],
  },
];

const scratchExamQuestions = [
  {
    type: "单选题",
    body: "在2026年春晚的《武 BOT》节目中，一群机器人表演空翻：它们落地后晃一下又能站稳，还会移动保持队形整齐。如果把机器人看成一台计算机，它的“输入设备”就像耳朵、眼睛，用来从外面接收信息。那么，下面哪一个选项不能当作机器人的“输入设备”？（ ）",
    choices: [
      "检测身体是否歪斜的“平衡传感器”（像感觉站得稳不稳的小秤）",
      "机器人内部安装好的“智能程序”（像它的大脑，用来思考和控制动作）",
      "用来接收人类指令的“遥控器”",
      "机器人的“摄像头眼睛”（用来拍下其他机器人的位置）",
    ],
  },
  {
    type: "单选题",
    body: "小猫角色向右移动后，如果想让它回到起点，最合适的积木是（ ）。",
    choices: ["说 你好", "移到 x:0 y:0", "等待 1 秒", "播放声音"],
  },
  {
    type: "单选题",
    body: "下面哪个积木通常用来做重复动作？（ ）",
    choices: ["重复执行", "停止所有", "询问并等待", "隐藏"],
  },
  {
    type: "判断题",
    body: "在图形化编程中，事件积木常用于启动程序。",
    choices: ["正确", "错误"],
  },
  {
    type: "编程题",
    body: "请设计一个小程序：点击绿旗后，角色先向右移动 10 步，再说“完成”。",
    choices: [],
  },
];

const $ = (selector) => document.querySelector(selector);

const views = {
  landing: $('[data-view="landing"]'),
  dashboard: $('[data-view="dashboard"]'),
  codeProblem: $('[data-view="codeProblem"]'),
  exam: $('[data-view="exam"]'),
  scratchExam: $('[data-view="scratchExam"]'),
  result: $('[data-view="result"]'),
};

function languageKey(language) {
  if (language === "Python") return "python";
  if (language === "C++") return "cpp";
  return "scratch";
}

function languageLabel() {
  if (state.selectedSystem === "scratch") return "图形化编程";
  return state.account?.language || "C++";
}

function questions() {
  if (state.selectedSystem === "scratch") {
    return questionBank.filter((question) => question.tags.includes("scratch"));
  }
  const language = state.language;
  return questionBank.filter((question) => question.tags.includes("all") || question.tags.includes(language));
}

function showView(name) {
  state.view = name;
  Object.entries(views).forEach(([viewName, element]) => {
    element.classList.toggle("hidden", viewName !== name);
  });
}

function updateClock() {
  const now = new Date();
  const text = now.toLocaleTimeString("zh-CN", { hour12: false });
  const landingClock = $("#landingClock");
  const dashboardClock = $("#dashboardClock");
  const codeProblemClock = $("#codeProblemClock");
  if (landingClock) landingClock.textContent = text;
  if (dashboardClock) dashboardClock.textContent = text;
  if (codeProblemClock) codeProblemClock.textContent = text;
}

function applySystemMode() {
  document.body.dataset.system = state.selectedSystem;
  const isScratch = state.selectedSystem === "scratch";
  $("#landingTitle").textContent = isScratch ? "图形化编程模拟考试系统" : "试机须知";
  $("#landingSubtitle").textContent = isScratch
    ? "请输入准考证号和密码，进入我的考试列表。"
    : "本页面用于熟悉 GESP 试机登录、考试列表、题目入口和提交流程。";
  $("#loginTitle").textContent = isScratch ? "考生登录" : "登录考试系统";
  $("#usernameLabel").textContent = isScratch ? "准考证号" : "用户名";
  $("#passwordLabel").textContent = isScratch ? "密码（证件号后 6 位）" : "密码";
  $("#username").placeholder = isScratch ? "请输入准考证号" : "用户名";
  $("#password").placeholder = isScratch ? "请输入身份证号或者护照号后 6 位" : "密码";
  $("#loginHelp").textContent = isScratch
    ? "图形化系统测试账号和密码均为 062234。"
    : "编程系统请输入附件中的试机用户名和密码。";
  document.querySelector("#loginForm .primary").textContent = isScratch ? "考 生 登 录" : "登入";
}

async function loadSummary() {
  try {
    const response = await fetch("/api/gesp/trial-summary");
    const payload = await response.json();
    const summary = Object.entries(payload.summary || {})
      .map(([language, levels]) => `${language}：${Object.values(levels).reduce((sum, value) => sum + value, 0)} 个`)
      .join("，");
    $("#trialSummary").textContent = `已加载 ${payload.count || 0} 个试机账号。${summary}`;
  } catch {
    $("#trialSummary").textContent = "试机账号读取失败，请确认服务端已启动。";
  }
}

async function login(event) {
  event.preventDefault();
  $("#loginError").textContent = "";
  const username = $("#username").value.trim();
  const password = $("#password").value.trim();
  if (!username || !password) {
    $("#loginError").textContent = "请输入用户名和密码。";
    return;
  }

  try {
    const response = await fetch("/api/gesp/trial-login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password, system: state.selectedSystem }),
    });
    const payload = await response.json();
    if (!response.ok) {
      $("#loginError").textContent = payload.error || "登录失败。";
      return;
    }
    state.account = payload.account;
    state.language = state.selectedSystem === "scratch" ? "scratch" : languageKey(payload.account.language);
    state.level = payload.account.level || "1";
    renderDashboard();
    showView("dashboard");
  } catch {
    $("#loginError").textContent = "无法连接 xiaowuOS svc。";
  }
}

function renderDashboard() {
  const isScratch = state.selectedSystem === "scratch";
  const language = state.account.language || "C++";
  $("#dashboardEyebrow").textContent = isScratch ? `${state.account.name}⌄` : `${language}${state.account.level || "1"}级考生01⌄`;
  $("#dashboardTitle").textContent = isScratch ? "我的考试" : "考试列表";
  $("#examListTitle").textContent = `CCF GESP 2026年6月认证 ${language} ${state.account.level || "1"}级 - 环境测试`;
  $("#scratchUserName").textContent = state.account.name || "考生";
  document.querySelector(".code-dashboard").classList.toggle("hidden", isScratch);
  document.querySelector(".scratch-dashboard").classList.toggle("hidden", !isScratch);
  document.querySelectorAll(".code-only").forEach((item) => item.classList.toggle("hidden", isScratch));
  document.querySelectorAll(".problem-row").forEach((row) => {
    row.textContent = row.textContent.replace(/C\+\+|Python/g, language);
    row.textContent = row.textContent.replace(/[1-8]级/g, `${state.account.level || "1"}级`);
  });
  renderSubmissionRows();
  renderScoreRows();
  switchDashboardTab("list");
}

function openCodeProblem(kind) {
  state.currentCodeProblem = kind;
  $("#codeProblemUser").textContent = `${state.account?.name || "试机用户"}⌄`;
  $("#codeProblemContent").innerHTML = ["program1", "program2"].includes(kind)
    ? renderOfficialProgram(kind)
    : renderOfficialObjective(kind);
  showView("codeProblem");
}

function renderOfficialObjective(kind) {
  const label = kind === "judge" ? "判断题" : "选择题";
  const language = state.account?.language || "C++";
  const level = state.account?.level || "1";
  const base = codeObjectiveSamples[kind] || [];
  const items = Array.from({ length: 15 }, (_, index) => base[index % base.length]);
  return `
    <h1 class="code-problem-title">CCF GESP 模拟测试 ${escapeHtml(language)} ${escapeHtml(level)}级 ${label}</h1>
    <p class="completion-line">共有 15 道题目，已完成 ${countObjectiveAnswers(kind)} 道题目</p>
    ${items.map((item, index) => renderOfficialQuestion(kind, item, index)).join("")}
  `;
}

function renderOfficialQuestion(kind, item, index) {
  const key = `${kind}-${index + 1}`;
  const selected = state.answers[key];
  return `
    <article class="official-question">
      <h3>第 ${index + 1} 题 ${escapeHtml(item.prompt)}</h3>
      ${item.code ? `<pre>${escapeHtml(item.code)}</pre>` : ""}
      <div class="official-options">
        ${item.options.map((option, optionIndex) => {
          const letter = String.fromCharCode(65 + optionIndex);
          return `<button class="official-option ${selected === letter ? "selected" : ""}" type="button" data-objective-key="${key}" data-objective-answer="${letter}">
            <span>${letter}</span>${escapeHtml(option)}
          </button>`;
        }).join("")}
      </div>
    </article>
  `;
}

function countObjectiveAnswers(kind) {
  return Object.keys(state.answers).filter((key) => key.startsWith(`${kind}-`)).length;
}

function renderOfficialProgram(kind) {
  const language = state.account?.language || "C++";
  const level = state.account?.level || "1";
  const item = codeProgramSamples[kind] || codeProgramSamples.program1;
  const answerKey = `${kind}-code`;
  if (!state.answers[answerKey]) {
    state.answers[answerKey] = getTemplate({ template: { cpp: "#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n    // 在这里完成程序\n    return 0;\n}\n" } });
  }
  return `
    <h1 class="code-problem-title">CCF GESP 模拟测试 ${escapeHtml(language)} ${escapeHtml(level)}级 ${kind === "program1" ? "编程题1" : "编程题2"}</h1>
    <p class="limit-line">时间限制 1000 ms　空间限制 512 MB　测试点数 10　总分值 ${item.score}</p>
    <div class="official-program">
      <section>
        <h2>${escapeHtml(item.title)}</h2>
        <h2>题面描述</h2>
        <p>${escapeHtml(item.body)}</p>
        <h2>输入格式</h2>
        <p>${escapeHtml(item.input)}</p>
        <h2>输出格式</h2>
        <p>${escapeHtml(item.output)}</p>
        <h2>样例</h2>
        <div class="sample-box"><strong>输入样例</strong><code>${escapeHtml(item.sampleIn)}</code></div>
        <div class="sample-box"><strong>输出样例</strong><code>${escapeHtml(item.sampleOut)}</code></div>
        <h2>语言及编译选项</h2>
        <table class="tuoj-table"><tbody><tr><td>#</td><td>名称</td><td>编译器</td><td>额外参数</td><td>代码长度限制</td></tr><tr><td>1</td><td>g++ with std11</td><td>g++</td><td>-O2 -std=c++11 -DONLINE_JUDGE</td><td>65536 B</td></tr></tbody></table>
      </section>
      <aside class="submit-panel">
        <h3>递交历史</h3>
        <ul class="submit-history">
          ${programHistoryRows(kind, item).map((row) => `<li><span>#${row.id}</span><span class="${submissionClass(row.status)}">${row.status}</span><span>${row.score}</span></li>`).join("")}
        </ul>
        <h3>递交答案</h3>
        <div class="submit-box">
          <select><option>g++ with std11</option></select>
          <textarea id="officialCodeEditor" spellcheck="false">${escapeHtml(state.answers[answerKey])}</textarea>
          <button id="officialSubmit" class="primary small" type="button">递交评测</button>
        </div>
      </aside>
    </div>
  `;
}

function programHistoryRows(kind, item) {
  const localRows = state.submissions
    .filter((submission) => submission.kind === kind)
    .map((submission) => ({
      id: submission.id,
      status: submission.status,
      score: submission.score,
    }));
  const referenceRows = item.history.map((row) => ({
    id: row[0],
    status: row[1],
    score: row[2],
  }));
  return [...localRows, ...referenceRows];
}

function submissionClass(text) {
  if (text.includes("正确")) return "state-ok";
  if (text.includes("等待") || text.includes("正在")) return "state-pending";
  return "state-error";
}

function submitOfficialProgram() {
  const editor = $("#officialCodeEditor");
  if (!editor) return;
  const kind = state.currentCodeProblem;
  const code = editor.value;
  state.answers[`${kind}-code`] = code;
  const item = codeProgramSamples[kind] || codeProgramSamples.program1;
  const result = evaluateOfficialProgram(kind, code);
  const submission = {
    id: String(state.submissionSeq++),
    kind,
    title: kind === "program1" ? "编程题1" : "编程题2",
    language: state.account?.language || "C++",
    status: result.status,
    score: result.score,
    time: new Date().toLocaleTimeString("zh-CN", { hour12: false }),
    details: result.details,
  };
  state.submissions.unshift(submission);
  state.codeScores[kind] = Math.max(Number(state.codeScores[kind] || 0), Number(result.score || 0));
  state.lastResult = {
    score: Object.values(state.codeScores).reduce((sum, value) => sum + Number(value || 0), 0),
    breakdown: [],
  };
  renderSubmissionRows();
  renderScoreRows();
  $("#codeProblemContent").innerHTML = renderOfficialProgram(kind);
  showSubmitFeedback(result, item);
}

function evaluateOfficialProgram(kind, code) {
  const normalized = String(code).toLowerCase();
  if (!normalized.includes("main") || !normalized.includes("return")) {
    return buildJudgeResult("编译错误", 0, "未检测到完整 main 函数。");
  }
  if (kind === "program1") {
    const hasInput = normalized.includes("cin") || normalized.includes("scanf");
    const hasOutput = normalized.includes("cout") || normalized.includes("printf");
    const hasFourthPower = normalized.includes("pow") || normalized.includes("* b * b * b") || normalized.includes("*b*b*b") || normalized.includes("sqrt");
    if (hasInput && hasOutput && hasFourthPower) {
      return buildJudgeResult("答案正确", 25, "样例与关键逻辑检查通过。");
    }
    if (hasInput && hasOutput) {
      return buildJudgeResult("答案错误", 12.5, "输入输出结构存在，但缺少四次方判断关键逻辑。");
    }
    return buildJudgeResult("答案错误", 0, "未检测到完整输入输出结构。");
  }
  const hasLoop = normalized.includes("for") || normalized.includes("while");
  const hasOutput = normalized.includes("cout") || normalized.includes("printf");
  if (hasLoop && hasOutput) return buildJudgeResult("答案正确", 25, "样例与关键逻辑检查通过。");
  if (hasOutput) return buildJudgeResult("答案错误", 10, "有输出，但缺少必要循环或统计逻辑。");
  return buildJudgeResult("答案错误", 0, "未检测到有效输出。");
}

function buildJudgeResult(status, score, message) {
  const perPoint = 2.5;
  const acceptedCount = status === "答案正确" ? 10 : status === "编译错误" ? 0 : Math.round(Number(score || 0) / perPoint);
  const details = Array.from({ length: 10 }, (_, index) => {
    const accepted = index < acceptedCount;
    return {
      id: index + 1,
      status: status === "编译错误" ? "CE" : accepted ? "AC" : "WA",
      time: status === "编译错误" ? "-" : `${12 + index * 3} ms`,
      memory: status === "编译错误" ? "-" : `${8 + (index % 3)} MB`,
      score: accepted ? perPoint : 0,
    };
  });
  return { status, score, message, details };
}

function showSubmitFeedback(result, item) {
  const feedback = document.createElement("div");
  feedback.className = `submit-feedback ${submissionClass(result.status)}`;
  feedback.innerHTML = `
    <strong>递交完成：${escapeHtml(result.status)}，得分 ${result.score}/${item.score}</strong>
    <p>${escapeHtml(result.message)}</p>
    <table class="judge-table">
      <thead><tr><th>测试点</th><th>结果</th><th>耗时</th><th>内存</th><th>得分</th></tr></thead>
      <tbody>
        ${result.details.map((point) => `
          <tr>
            <td>#${point.id}</td>
            <td class="${point.status === "AC" ? "state-ok" : point.status === "CE" ? "state-error" : "state-error"}">${point.status}</td>
            <td>${point.time}</td>
            <td>${point.memory}</td>
            <td>${point.score}</td>
          </tr>
        `).join("")}
      </tbody>
    </table>
  `;
  $("#codeProblemContent").prepend(feedback);
}

function startExam() {
  if (state.selectedSystem === "scratch") {
    startScratchFlow();
    return;
  }
  state.durationMinutes = Number($("#duration").value);
  state.remainingSeconds = state.durationMinutes * 60;
  state.currentIndex = 0;
  state.answers = {};
  state.marked = {};
  state.lastResult = null;

  const titleLanguage = languageLabel();
  $("#examTitle").textContent = `GESP ${titleLanguage} ${state.level} 级模拟`;
  showView("exam");
  renderExam();
  startTimer();
  $("#scratchNotice").classList.toggle("hidden", state.selectedSystem !== "scratch");
}

function startScratchFlow() {
  state.durationMinutes = Number($("#duration").value);
  state.remainingSeconds = state.durationMinutes * 60;
  state.scratchIndex = 0;
  state.answers = {};
  state.marked = {};
  $("#scratchExamName").textContent = state.account?.name || "图形化试机用户";
  $("#scratchBottomName").textContent = `考生姓名:${state.account?.name || "图形化试机用户"}`;
  $("#scratchNoticePage").classList.add("hidden");
  $("#scratchRealExam").classList.add("hidden");
  $("#scratchResumeModal").classList.remove("hidden");
  showView("scratchExam");
  startTimer();
}

function showScratchNoticePage() {
  $("#scratchResumeModal").classList.add("hidden");
  $("#scratchRealExam").classList.add("hidden");
  $("#scratchNoticePage").classList.remove("hidden");
}

function showScratchRealExam() {
  $("#scratchNoticePage").classList.add("hidden");
  $("#scratchResumeModal").classList.add("hidden");
  $("#scratchRealExam").classList.remove("hidden");
  renderScratchExamNav();
  renderScratchExamQuestion();
}

function startTimer() {
  clearInterval(state.timerId);
  updateTimer();
  state.timerId = setInterval(() => {
    state.remainingSeconds -= 1;
    updateTimer();
    if (state.remainingSeconds <= 0) {
      submitExam();
    }
  }, 1000);
}

function updateTimer() {
  const seconds = Math.max(0, state.remainingSeconds);
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  const timerText = `${String(minutes).padStart(2, "0")}:${String(rest).padStart(2, "0")}`;
  $("#timer").textContent = timerText;
  const scratchCountdown = $("#scratchCountdown");
  if (scratchCountdown) {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    scratchCountdown.textContent = `距离结束:${String(hours).padStart(2, "0")}:${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  }
}

function renderScratchExamNav() {
  renderScratchNumberGroup("#scratchSingleNav", 1, 10);
  renderScratchNumberGroup("#scratchJudgeNav", 11, 15);
  renderScratchNumberGroup("#scratchProgramNav", 16, 17);
}

function renderScratchNumberGroup(selector, start, end) {
  const target = $(selector);
  target.innerHTML = "";
  for (let number = start; number <= end; number += 1) {
    const index = number - 1;
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = number;
    button.classList.toggle("current", index === state.scratchIndex);
    button.classList.toggle("answered", Boolean(state.answers[`scratch-${number}`]));
    button.addEventListener("click", () => {
      state.scratchIndex = index;
      renderScratchExamNav();
      renderScratchExamQuestion();
    });
    target.appendChild(button);
  }
}

function scratchQuestionForIndex(index) {
  if (index < 10) return { ...scratchExamQuestions[index % 3], type: "单选题" };
  if (index < 15) return { ...scratchExamQuestions[3], type: "判断题" };
  return { ...scratchExamQuestions[4], type: "编程题" };
}

function renderScratchExamQuestion() {
  const number = state.scratchIndex + 1;
  const question = scratchQuestionForIndex(state.scratchIndex);
  $("#scratchQuestionTitle").textContent = `${number}. ${question.type}`;
  $("#scratchQuestionBody").textContent = question.body;
  $("#scratchProgramArea").classList.toggle("hidden", question.type !== "编程题");
  $("#scratchChoiceList").classList.toggle("hidden", question.type === "编程题");
  if (question.type === "编程题") {
    $("#scratchProgramAnswer").value = state.answers[`scratch-${number}`] || "";
    return;
  }
  const selected = state.answers[`scratch-${number}`];
  $("#scratchChoiceList").innerHTML = question.choices.map((choice, index) => {
    const letter = String.fromCharCode(65 + index);
    return `<button class="scratch-choice ${selected === letter ? "selected" : ""}" type="button" data-scratch-answer="${letter}">
      <strong>${letter}</strong><span>${escapeHtml(choice)}</span>
    </button>`;
  }).join("");
}

function saveScratchProgramAnswer() {
  const editor = $("#scratchProgramAnswer");
  if (!editor || editor.closest(".hidden")) return;
  state.answers[`scratch-${state.scratchIndex + 1}`] = editor.value;
}

function moveScratchQuestion(delta) {
  saveScratchProgramAnswer();
  state.scratchIndex = Math.max(0, Math.min(16, state.scratchIndex + delta));
  renderScratchExamNav();
  renderScratchExamQuestion();
}

function currentQuestion() {
  return questions()[state.currentIndex];
}

function renderExam() {
  renderQuestionNav();
  renderQuestion();
  updateAnsweredCount();
}

function renderQuestionNav() {
  const nav = $("#questionNav");
  nav.innerHTML = "";
  questions().forEach((question, index) => {
    const button = document.createElement("button");
    button.className = "nav-item";
    button.textContent = index + 1;
    button.classList.toggle("current", index === state.currentIndex);
    button.classList.toggle("answered", isAnswered(question));
    button.classList.toggle("marked", Boolean(state.marked[question.id]));
    button.addEventListener("click", () => {
      saveCurrentEditor();
      state.currentIndex = index;
      renderExam();
    });
    nav.appendChild(button);
  });
}

function renderQuestion() {
  const question = currentQuestion();
  $("#questionType").textContent = question.type === "program" ? "编程题" : question.type === "scratch" ? "图形化题" : question.type === "judge" ? "判断题" : "单选题";
  $("#questionScore").textContent = `${question.score} 分`;
  $("#questionTitle").textContent = `${state.currentIndex + 1}. ${question.title}`;
  $("#questionBody").textContent = question.body;
  $("#markQuestion").textContent = state.marked[question.id] ? "取消标记" : "标记";

  $("#choiceArea").classList.toggle("hidden", !["single", "judge"].includes(question.type));
  $("#codeArea").classList.toggle("hidden", question.type !== "program");
  $("#scratchArea").classList.toggle("hidden", question.type !== "scratch");

  if (question.type === "program") {
    renderCodeQuestion(question);
  } else if (question.type === "scratch") {
    renderScratchQuestion(question);
  } else {
    renderChoices(question);
  }

  $("#prevQuestion").disabled = state.currentIndex === 0;
  $("#nextQuestion").textContent = state.currentIndex === questions().length - 1 ? "完成检查" : "下一题";
}

function renderChoices(question) {
  const area = $("#choiceArea");
  area.innerHTML = "";
  const selected = state.answers[question.id];
  question.choices.forEach((choice, index) => {
    const letter = String.fromCharCode(65 + index);
    const button = document.createElement("button");
    button.className = "choice";
    button.classList.toggle("selected", selected === letter);
    button.innerHTML = `<strong>${letter}</strong><span>${escapeHtml(choice)}</span>`;
    button.addEventListener("click", () => {
      state.answers[question.id] = letter;
      renderExam();
    });
    area.appendChild(button);
  });
}

function renderCodeQuestion(question) {
  const editor = $("#codeEditor");
  if (state.answers[question.id] === undefined) {
    state.answers[question.id] = getTemplate(question);
  }
  editor.value = state.answers[question.id];
  renderProgramShell(question);
}

function renderProgramShell(question) {
  const codeArea = $("#codeArea");
  const languageName = state.language === "python" ? "Python 3" : "g++ with std11";
  codeArea.innerHTML = `
    <div class="program-shell">
      <section class="program-statement">
        <h3>${escapeHtml(question.title.replace("编程题：", ""))}</h3>
        <div class="statement-body">
          <strong>题目描述</strong>
          <p>${escapeHtml(question.body)}</p>
          <div class="sample-box">
            <strong>语言及编译选项</strong>
            <code># 名称: ${languageName}\n代码长度限制: 65536 B</code>
          </div>
        </div>
      </section>
      <aside class="submit-panel">
        <h3>递交历史</h3>
        <ul class="submit-history">
          <li><span>#890005</span><span class="state-pending">等待评测</span><span>0</span></li>
          <li><span>#889980</span><span class="state-error">答案错误</span><span>22.5</span></li>
          <li><span>#889973</span><span class="state-error">编译错误</span><span>0</span></li>
        </ul>
        <h3>递交答案</h3>
        <div class="submit-box">
          <select aria-label="语言和编译选项">
            <option>${languageName}</option>
          </select>
          <textarea id="codeEditor" spellcheck="false"></textarea>
          <button id="inlineSubmit" class="primary small" type="button">递交评测</button>
        </div>
      </aside>
    </div>
  `;
  $("#codeEditor").value = state.answers[question.id];
  $("#codeEditor").addEventListener("input", (event) => {
    state.answers[currentQuestion().id] = event.target.value;
    renderQuestionNav();
    updateAnsweredCount();
  });
  $("#inlineSubmit").addEventListener("click", () => {
    saveCurrentEditor();
    state.lastResult = gradeExam();
    renderSubmissionRows();
    renderScoreRows();
    alert("已递交评测。本地练习版已生成模拟评测结果。");
  });
}

function renderScratchQuestion(question) {
  const editor = $("#scratchEditor");
  if (state.answers[question.id] === undefined) {
    state.answers[question.id] = "";
  }
  editor.value = state.answers[question.id];
  $("#stageHint").textContent = question.title;
}

function getTemplate(question) {
  return question.template[state.language] || question.template.cpp || "";
}

function saveCurrentEditor() {
  const question = currentQuestion();
  if (!question) return;
  if (question.type === "program") {
    state.answers[question.id] = $("#codeEditor").value;
  }
  if (question.type === "scratch") {
    state.answers[question.id] = $("#scratchEditor").value;
  }
}

function isAnswered(question) {
  const answer = state.answers[question.id];
  return typeof answer === "string" && answer.trim().length > 0;
}

function updateAnsweredCount() {
  const all = questions();
  const answered = all.filter(isAnswered).length;
  $("#answeredCount").textContent = `${answered}/${all.length}`;
}

function submitExam() {
  saveCurrentEditor();
  clearInterval(state.timerId);
  const result = gradeExam();
  state.lastResult = result;
  $("#scoreText").textContent = `${result.score} 分`;
  $("#resultSummary").textContent = `共 ${result.total} 分，已作答 ${result.answered}/${questions().length} 题。${result.score >= 80 ? "状态不错，可以进入下一轮训练。" : "建议回看错题，再练一次基础题。"}`;
  renderBreakdown(result);
  showView("result");
}

function switchDashboardTab(tab) {
  document.querySelectorAll("[data-dashboard-tab]").forEach((button) => {
    button.classList.toggle("active", button.dataset.dashboardTab === tab);
  });
  document.querySelectorAll("[data-dashboard-panel]").forEach((panel) => {
    panel.classList.toggle("hidden", panel.dataset.dashboardPanel !== tab);
  });
}

function renderSubmissionRows() {
  const target = $("#submissionRows");
  if (!target) return;
  const language = state.account?.language || "C++";
  const now = new Date().toLocaleTimeString("zh-CN", { hour12: false });
  const localRows = state.submissions.map((submission) => `
    <tr>
      <td>${submission.id}</td>
      <td>${escapeHtml(submission.title)}</td>
      <td>${escapeHtml(submission.language)}</td>
      <td class="${submissionClass(submission.status)}">${escapeHtml(submission.status)}</td>
      <td>${submission.score}</td>
      <td>${escapeHtml(submission.time)}</td>
    </tr>
  `).join("");
  target.innerHTML = `
    ${localRows}
    <tr><td>890005</td><td>编程题1</td><td>${escapeHtml(language)}</td><td class="state-pending">等待评测</td><td>0</td><td>${now}</td></tr>
    <tr><td>889980</td><td>编程题1</td><td>${escapeHtml(language)}</td><td class="state-error">答案错误</td><td>22.5</td><td>14:19:29</td></tr>
    <tr><td>889973</td><td>编程题1</td><td>${escapeHtml(language)}</td><td class="state-error">编译错误</td><td>0</td><td>14:19:06</td></tr>
  `;
}

function renderScoreRows() {
  const target = $("#scoreRows");
  if (!target) return;
  const rows = [
    { key: "choice", title: "CCF GESP 模拟测试 选择题", total: 25, score: countObjectiveAnswers("choice") ? "已作答" : "-" },
    { key: "judge", title: "CCF GESP 模拟测试 判断题", total: 25, score: countObjectiveAnswers("judge") ? "已作答" : "-" },
    { key: "program1", title: "CCF GESP 模拟测试 编程题1", total: 25, score: state.codeScores.program1 },
    { key: "program2", title: "CCF GESP 模拟测试 编程题2", total: 25, score: state.codeScores.program2 },
  ];
  target.innerHTML = rows.map((row) => {
    const score = row.score ?? "-";
    const numericScore = typeof score === "number" ? score : null;
    const status = numericScore === null ? (score === "已作答" ? "已作答" : "未评测") : numericScore >= row.total ? "通过" : "未满分";
    const statusClass = numericScore === null ? "state-pending" : numericScore >= row.total ? "state-ok" : "state-error";
    return `<tr><td>${escapeHtml(row.title)}</td><td>${row.total}</td><td>${score}</td><td class="${statusClass}">${status}</td></tr>`;
  }).join("");
}

function gradeExam() {
  let score = 0;
  let answered = 0;
  const breakdown = [];

  questions().forEach((question) => {
    const answer = state.answers[question.id] || "";
    if (String(answer).trim()) {
      answered += 1;
    }
    const gained = ["program", "scratch"].includes(question.type) ? gradeKeywordQuestion(question, answer) : answer === question.answer ? question.score : 0;
    score += gained;
    breakdown.push({ question, gained });
  });

  return {
    score,
    answered,
    total: questions().reduce((sum, question) => sum + question.score, 0),
    breakdown,
  };
}

function gradeKeywordQuestion(question, answer) {
  const normalized = String(answer).toLowerCase();
  const keywords = question.type === "scratch" ? question.keywords : question.keywords[state.language] || question.keywords.cpp;
  const hits = keywords.filter((keyword) => normalized.includes(keyword.toLowerCase())).length;
  if (hits === keywords.length) return question.score;
  if (hits >= Math.max(2, keywords.length - 1)) return Math.round(question.score * 0.7);
  if (hits >= 1) return Math.round(question.score * 0.35);
  return 0;
}

function renderBreakdown(result) {
  const area = $("#resultBreakdown");
  const objective = result.breakdown.filter((item) => !["program", "scratch"].includes(item.question.type));
  const practical = result.breakdown.filter((item) => ["program", "scratch"].includes(item.question.type));
  const objectiveScore = objective.reduce((sum, item) => sum + item.gained, 0);
  const practicalScore = practical.reduce((sum, item) => sum + item.gained, 0);
  area.innerHTML = `
    <div class="breakdown-card"><strong>${objectiveScore}</strong><span>客观题</span></div>
    <div class="breakdown-card"><strong>${practicalScore}</strong><span>实操题</span></div>
    <div class="breakdown-card"><strong>${Object.keys(state.marked).length}</strong><span>标记题</span></div>
  `;
}

function escapeHtml(text) {
  return String(text)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

document.querySelectorAll(".system-card").forEach((button) => {
  button.addEventListener("click", () => {
    state.selectedSystem = button.dataset.system;
    document.querySelectorAll(".system-card").forEach((item) => item.classList.toggle("selected", item === button));
    applySystemMode();
    if (state.selectedSystem === "scratch") {
      $("#username").value = "062234";
      $("#password").value = "062234";
      $("#trialSummary").textContent = "图形化编程模拟系统入口：https://ccf.scratchoj.com/examv/#/，本地试机码：062234。";
    } else {
      if ($("#username").value === "062234" || !$("#username").value.trim()) $("#username").value = "gesp_202606_c2_test_50";
      if ($("#password").value === "062234" || !$("#password").value.trim()) $("#password").value = "shHLM7";
      loadSummary();
    }
  });
});

document.querySelectorAll(".blocks button").forEach((button) => {
  button.addEventListener("click", () => {
    const editor = $("#scratchEditor");
    const prefix = editor.value.trim() ? " → " : "";
    editor.value = `${editor.value}${prefix}${button.dataset.block}`;
    state.answers[currentQuestion().id] = editor.value;
    renderQuestionNav();
    updateAnsweredCount();
  });
});

$("#loginForm").addEventListener("submit", login);
$("#startExam").addEventListener("click", startExam);
document.querySelectorAll("[data-start-exam]").forEach((button) => {
  button.addEventListener("click", startExam);
});
document.querySelectorAll("[data-code-problem]").forEach((button) => {
  button.addEventListener("click", () => openCodeProblem(button.dataset.codeProblem));
});
document.querySelectorAll("[data-dashboard-tab]").forEach((button) => {
  button.addEventListener("click", () => {
    showView("dashboard");
    switchDashboardTab(button.dataset.dashboardTab);
  });
});
$("#backToExamList").addEventListener("click", () => {
  showView("dashboard");
  switchDashboardTab("list");
});
$("#codeProblemContent").addEventListener("click", (event) => {
  const option = event.target.closest("[data-objective-key]");
  if (option) {
    state.answers[option.dataset.objectiveKey] = option.dataset.objectiveAnswer;
    $("#codeProblemContent").innerHTML = renderOfficialObjective(state.currentCodeProblem);
    return;
  }
  if (event.target.id === "officialSubmit") {
    submitOfficialProgram();
  }
});
$("#logout").addEventListener("click", () => {
  clearInterval(state.timerId);
  state.account = null;
  $("#password").value = "";
  showView("landing");
});
$("#submitExam").addEventListener("click", () => {
  if (confirm("确定交卷吗？")) {
    submitExam();
  }
});
$("#prevQuestion").addEventListener("click", () => {
  saveCurrentEditor();
  state.currentIndex = Math.max(0, state.currentIndex - 1);
  renderExam();
});
$("#nextQuestion").addEventListener("click", () => {
  saveCurrentEditor();
  if (state.currentIndex === questions().length - 1) {
    if (confirm("已经到最后一题，是否交卷？")) {
      submitExam();
    }
    return;
  }
  state.currentIndex = Math.min(questions().length - 1, state.currentIndex + 1);
  renderExam();
});
$("#markQuestion").addEventListener("click", () => {
  const question = currentQuestion();
  if (state.marked[question.id]) {
    delete state.marked[question.id];
  } else {
    state.marked[question.id] = true;
  }
  renderExam();
});
$("#codeEditor").addEventListener("input", (event) => {
  state.answers[currentQuestion().id] = event.target.value;
  renderQuestionNav();
  updateAnsweredCount();
});
$("#scratchEditor").addEventListener("input", (event) => {
  state.answers[currentQuestion().id] = event.target.value;
  renderQuestionNav();
  updateAnsweredCount();
});
$("#resetCode").addEventListener("click", () => {
  const question = currentQuestion();
  state.answers[question.id] = getTemplate(question);
  renderQuestion();
  renderQuestionNav();
});
$("#scratchContinue").addEventListener("click", () => {
  $("#scratchNotice").classList.add("hidden");
});
$("#scratchRestart").addEventListener("click", () => {
  state.answers = {};
  state.marked = {};
  renderExam();
  $("#scratchNotice").classList.add("hidden");
});
$("#scratchResumeContinue").addEventListener("click", showScratchNoticePage);
$("#scratchResumeReset").addEventListener("click", () => {
  state.answers = {};
  showScratchNoticePage();
});
$("#scratchStartRealExam").addEventListener("click", showScratchRealExam);
$("#scratchChoiceList").addEventListener("click", (event) => {
  const button = event.target.closest("[data-scratch-answer]");
  if (!button) return;
  state.answers[`scratch-${state.scratchIndex + 1}`] = button.dataset.scratchAnswer;
  renderScratchExamNav();
  renderScratchExamQuestion();
});
$("#scratchProgramAnswer").addEventListener("input", (event) => {
  state.answers[`scratch-${state.scratchIndex + 1}`] = event.target.value;
  renderScratchExamNav();
});
$("#scratchPrev").addEventListener("click", () => moveScratchQuestion(-1));
$("#scratchNext").addEventListener("click", () => moveScratchQuestion(1));
$("#scratchSaveAnswer").addEventListener("click", () => {
  saveScratchProgramAnswer();
  renderScratchExamNav();
  $("#scratchGuideTip").classList.remove("hidden");
});
$("#scratchSubmitPaper").addEventListener("click", () => {
  if (confirm("确定交卷吗？交卷后不可再修改和保存作答。")) {
    submitExam();
  }
});
$("#scratchListMode").addEventListener("click", () => {
  renderScratchExamNav();
  $("#scratchGuideTip").classList.remove("hidden");
});
$("#scratchGuideClose").addEventListener("click", () => {
  $("#scratchGuideTip").classList.add("hidden");
});
$("#restartExam").addEventListener("click", () => {
  clearInterval(state.timerId);
  renderDashboard();
  showView("dashboard");
});
$("#reviewExam").addEventListener("click", () => {
  showView("exam");
  renderExam();
});

loadSummary();
applySystemMode();
updateClock();
setInterval(updateClock, 1000);

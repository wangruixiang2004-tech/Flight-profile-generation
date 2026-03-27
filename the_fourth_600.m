%% 倾转旋翼飞行器功率剖面生成器 (600s 平稳微小波动巡航版)
clear; clc; close all;

% 设置采样频率 (10Hz)
dt = 0.1; 

%% 阶段 1：起飞与垂直爬升 (Mode 1)
% 时间段:[0, 40s) 
t1_nodes = [0, 10, 20, 30, 40];
p1_nodes =[120, 122, 125, 118, 118]; 
t1 = (0 : dt : 40-dt)';
P1 = pchip(t1_nodes, p1_nodes, t1);
M1 = ones(size(t1)) * 1;

%% 阶段 2：第一次过渡飞行 (Mode 2)
% 时间段:[40s, 80s) 
t2_nodes =[40, 45, 50, 60, 75, 80];
p2_nodes =[42, 20, 35, 93, 75, 70]; 
t2 = (40 : dt : 80-dt)';
P2 = pchip(t2_nodes, p2_nodes, t2);
M2 = ones(size(t2)) * 2;

%% 阶段 3：前飞巡航 (Mode 3) —— 【平稳微小波动设计】
% 时间段:[80s, 480s) 
t3 = (80 : dt : 480-dt)';
t_rel = t3 - 80; % 巡航段相对时间 (0 ~ 400s)

% 1. 基础衰减趋势：从 70kW 快速且平滑地收敛至 42kW (常数设为15，收敛更快)
tau = 15; 
P3_base = 42 + (70 - 42) * exp(-t_rel / tau);

% 2. 生成极微弱的波动 (幅度极小，仅 ±0.8kW，模拟平稳巡航的微小气流扰动)
wave1 = 0.6 * sin(2 * pi * t_rel / 120);       % 极慢速的长周期微调
wave2 = 0.3 * cos(2 * pi * t_rel / 35 + 1.2);  % 轻微的中周期振动
total_wave = wave1 + wave2;

% 3. 包络处理：保证波动平滑切入和退出
envelope = ones(size(t_rel));
idx_in = t_rel < 50; % 前 50 秒逐渐引入微小波动
envelope(idx_in) = t_rel(idx_in) / 50;
time_to_end = (480 - t3);
idx_out = time_to_end < 50; % 最后 50 秒逐渐平息波动
envelope(idx_out) = time_to_end(idx_out) / 50;

% 4. 合成 Mode 3 功率
P3 = P3_base + total_wave .* envelope;
M3 = ones(size(t3)) * 3;

%% 阶段 4：第二次过渡飞行与下降 (Mode 4)
% 时间段:[480s, 540s) 
t4_nodes =[480, 485, 510, 540];
p4_nodes = [26, 28, 30, 34]; 
t4 = (480 : dt : 540-dt)';
P4 = pchip(t4_nodes, p4_nodes, t4);
M4 = ones(size(t4)) * 4;

%% 阶段 5：着陆与悬停 (Mode 5)
% 时间段:[540s, 600s] 
t5_nodes =[540, 550, 560, 580, 600];
p5_nodes =[122, 112, 110, 108, 112];
t5 = (540 : dt : 600)';
P5 = pchip(t5_nodes, p5_nodes, t5);
M5 = ones(size(t5)) * 5;

%% 合并所有数据 (严格单调递增时间轴)
time = [t1; t2; t3; t4; t5];
P_req_ori = [P1; P2; P3; P4; P5];
Flight_Mode =[M1; M2; M3; M4; M5];

%% ================= 在命令窗口输出切换时刻日志 =================
fprintf('\n=========================================================\n');
fprintf('    ✈️ 倾转旋翼飞行器飞行剖面生成完毕 (600s 平稳微小波动版) ✈️\n');
fprintf('=========================================================\n');
fprintf('总仿真时长 : %.1f 秒 | 总数据点数: %d\n', time(end), length(time));
fprintf('巡航段时间 : %.1f 秒\n', 480 - 80);
fprintf('  ▶ 巡航内部动态：快速收敛至 42kW，保持 ±0.8kW 的极轻微波动\n');
fprintf('---------------------------------------------------------\n');
fprintf('【模式切换时刻表】(切换时刻精准归属新模式起点)\n');
fprintf('▶ 时刻 %7.1f s : Mode 1 (起飞阶段) -> Mode 2 (首次过渡)\n', 40.0);
fprintf('▶ 时刻 %7.1f s : Mode 2 (首次过渡) -> Mode 3 (前飞巡航)\n', 80.0);
fprintf('▶ 时刻 %7.1f s : Mode 3 (前飞巡航) -> Mode 4 (二次过渡)\n', 480.0);
fprintf('▶ 时刻 %7.1f s : Mode 4 (二次过渡) -> Mode 5 (悬停着陆)\n', 540.0);
fprintf('=========================================================\n\n');

%% 保存为 .mat 文件 
save('TiltRotor_Profile_600s_Smooth.mat', 'time', 'P_req_ori', 'Flight_Mode');

%% 绘制高质量验证图
fig = figure('Name', '600s Smooth Cruise Flight Profile', 'Color', 'w', 'Position',[100, 100, 900, 450]);

% 左侧 Y 轴：功率
yyaxis left
h1 = plot(time, P_req_ori, '-', 'LineWidth', 1.5, 'Color',[0 0.4470 0.7410]); 
ylabel('Power \it{P_{req\_ori}} \rm{(kW)}', 'FontName', 'Times New Roman', 'FontSize', 12);
ax = gca; ax.YColor = [0 0.4470 0.7410]; 
ylim([0, 140]);

% 右侧 Y 轴：飞行模式
yyaxis right
h2 = stairs(time, Flight_Mode, '-', 'LineWidth', 2.0, 'Color',[0.8500 0.3250 0.0980]); 
ylabel('Flight Mode', 'FontName', 'Times New Roman', 'FontSize', 12);
ax.YColor = [0.8500 0.3250 0.0980];
ylim([0, 6]); yticks(1:5);

% X 轴与图表修饰
xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', 12);
xlim([0, 600]);

% 添加垂直虚线标记精确的模式切换时刻
xlines_pos = [40, 80, 480, 540];
for i = 1:length(xlines_pos)
    xline(xlines_pos(i), '--k', 'LineWidth', 1.2, 'Alpha', 0.5, 'HandleVisibility', 'off');
end

lgd = legend([h1, h2], {'Power \it{P_{req\_ori}}', 'Flight Mode'}, 'Location', 'best');
set(lgd, 'FontName', 'Times New Roman', 'FontSize', 11, 'Box', 'off');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 11, 'TickDir', 'in', 'LineWidth', 1.0, 'XMinorTick', 'on');
box on; grid on; ax.GridAlpha = 0.2;
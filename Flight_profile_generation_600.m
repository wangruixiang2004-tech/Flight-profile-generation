%% 倾转旋翼飞行器功率剖面生成器 (600s 压缩版)
clear; clc; close all;

% 设置采样频率 (10Hz)
dt = 0.1; 

%% 阶段 1：起飞与垂直爬升 (Mode 1)
% 时间段:[0, 40s) | 准确到 39.9s 结束，40.0s 留给 Mode 2
t1_nodes =[0, 10, 20, 30, 40];
p1_nodes =[120, 122, 125, 118, 118]; % 模拟起飞初期的功率波动
t1 = (0 : dt : 40-dt)';
P1 = pchip(t1_nodes, p1_nodes, t1);
M1 = ones(size(t1)) * 1;

%% 阶段 2：第一次过渡飞行 (Mode 2)
% 时间段:[40s, 80s) | 准确从 40.0s 开始
t2_nodes =[40, 45, 50, 60, 75, 80];
p2_nodes =[42, 20, 35, 93, 75, 70]; % 完美复刻图片中骤降后拉高的形状
t2 = (40 : dt : 80-dt)';
P2 = pchip(t2_nodes, p2_nodes, t2);
M2 = ones(size(t2)) * 2;

%% 阶段 3：前飞巡航 (Mode 3) 
% 时间段:[80s, 480s) | 准确从 80.0s 开始，持续 400 秒
t3_nodes =[80, 100, 150, 480];
p3_nodes = [70, 45, 42, 42]; % 从过渡段平滑衰减并稳定在 42kW
t3 = (80 : dt : 480-dt)';
P3 = pchip(t3_nodes, p3_nodes, t3);
M3 = ones(size(t3)) * 3;

%% 阶段 4：第二次过渡飞行与下降 (Mode 4)
% 时间段:[480s, 540s) | 准确从 480.0s 开始
t4_nodes =[480, 485, 510, 540];
p4_nodes = [26, 28, 30, 34]; 
t4 = (480 : dt : 540-dt)';
P4 = pchip(t4_nodes, p4_nodes, t4);
M4 = ones(size(t4)) * 4;

%% 阶段 5：着陆与悬停 (Mode 5)
% 时间段:[540s, 600s] | 准确从 540.0s 开始，包含最终的 600.0s
t5_nodes =[540, 550, 560, 580, 600];
p5_nodes =[122, 112, 110, 108, 112];
t5 = (540 : dt : 600)';
P5 = pchip(t5_nodes, p5_nodes, t5);
M5 = ones(size(t5)) * 5;

%% 合并所有数据
time =[t1; t2; t3; t4; t5];
P_req_ori =[P1; P2; P3; P4; P5];
Flight_Mode = [M1; M2; M3; M4; M5];

%% ================= 在命令窗口输出切换时刻 =================
fprintf('\n======================================================\n');
fprintf('        ✈️ 倾转旋翼飞行器飞行剖面生成完毕 ✈️\n');
fprintf('======================================================\n');
fprintf('总仿真时长 : %.1f 秒\n', time(end));
fprintf('巡航段时间 : %.1f 秒 (80.0s -> 480.0s)\n', 480-80);
fprintf('------------------------------------------------------\n');
fprintf('【模式切换时刻表】(切换时刻精准归属于新模式起点)\n');
fprintf('▶ 时刻 %6.1f s : Mode 1 (垂直起飞)  -> Mode 2 (首次过渡)\n', 40.0);
fprintf('▶ 时刻 %6.1f s : Mode 2 (首次过渡)  -> Mode 3 (前飞巡航)\n', 80.0);
fprintf('▶ 时刻 %6.1f s : Mode 3 (前飞巡航)  -> Mode 4 (二次过渡)\n', 480.0);
fprintf('▶ 时刻 %6.1f s : Mode 4 (二次过渡)  -> Mode 5 (悬停着陆)\n', 540.0);
fprintf('======================================================\n\n');

%% 保存为 .mat 文件 (方便能量管理 Simulink 查表使用)
save('TiltRotor_Profile_600s.mat', 'time', 'P_req_ori', 'Flight_Mode');

%% 绘制验证图 (复刻 SCI 风格双轴图)
fig = figure('Name', '600s Generated Flight Profile', 'Color', 'w', 'Position', [100, 100, 800, 400]);

% 左轴：功率
yyaxis left
h1 = plot(time, P_req_ori, '-', 'LineWidth', 2.0, 'Color',[0 0.4470 0.7410]); 
ylabel('Power \it{P_{req\_ori}} \rm{(kW)}', 'FontName', 'Times New Roman', 'FontSize', 12);
ax = gca; ax.YColor = [0 0.4470 0.7410]; 
ylim([0, 140]);

% 右轴：飞行模式
yyaxis right
h2 = stairs(time, Flight_Mode, '-', 'LineWidth', 2.0, 'Color',[0.8500 0.3250 0.0980]); 
ylabel('Flight Mode', 'FontName', 'Times New Roman', 'FontSize', 12);
ax.YColor =[0.8500 0.3250 0.0980];
ylim([0, 6]); yticks(1:5);

% X轴与图表修饰
xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', 12);
xlim([0, time(end)]);

% 图注与学术风格设置
lgd = legend([h1, h2], {'Power \it{P_{req\_ori}}', 'Flight Mode'}, 'Location', 'best');
set(lgd, 'FontName', 'Times New Roman', 'FontSize', 10, 'Box', 'off');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 10, 'TickDir', 'in', 'LineWidth', 1.0, 'XMinorTick', 'on');
box on; grid on; ax.GridAlpha = 0.2;
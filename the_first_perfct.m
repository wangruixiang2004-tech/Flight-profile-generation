%% 倾转旋翼飞行器功率剖面生成器 (3000s 基于真实物理过渡时间的压缩版)
clear; clc; close all;

% 设置采样频率 (10Hz)
dt = 0.1; 

% 基于真实数据的各阶段时长提取
dur_m1 = 232.7;
dur_m2 = 63.2;
dur_m4 = 127.7;
dur_m5 = 184.7;
% 倒推计算巡航段时长，保证总时长为 3000s
dur_m3 = 3000.0 - (dur_m1 + dur_m2 + dur_m4 + dur_m5); 

% 计算精确的切换时刻 (用于数据生成与画图)
t_switch1 = dur_m1;                          % 232.7s
t_switch2 = t_switch1 + dur_m2;              % 295.9s
t_switch3 = t_switch2 + dur_m3;              % 2687.6s
t_switch4 = t_switch3 + dur_m4;              % 2815.3s
t_end     = 3000.0;                          % 3000.0s

%% 阶段 1：起飞与垂直爬升 (Mode 1)
% 时间段:[0, 232.7s) | 准确到 232.6s 结束
t1_nodes =[0, 50, 100, 200, t_switch1];
p1_nodes =[120, 122, 125, 118, 118]; 
t1 = (0 : dt : t_switch1 - dt)';
P1 = pchip(t1_nodes, p1_nodes, t1);
M1 = ones(size(t1)) * 1;

%% 阶段 2：第一次过渡飞行 (Mode 2)
% 时间段:[232.7s, 295.9s) | 准确从 232.7s 开始
t2_nodes =[t_switch1, t_switch1+10, t_switch1+20, t_switch1+35, t_switch1+50, t_switch2];
p2_nodes =[42, 20, 35, 93, 75, 70]; % 完美复刻倾转骤降后拉高的形状
t2 = (t_switch1 : dt : t_switch2 - dt)';
P2 = pchip(t2_nodes, p2_nodes, t2);
M2 = ones(size(t2)) * 2;

%% 阶段 3：前飞巡航 (Mode 3) 
% 时间段:[295.9s, 2687.6s) | 准确从 295.9s 开始
t3_nodes =[t_switch2, t_switch2+50, t_switch2+150, t_switch3];
p3_nodes =[70, 45, 42, 42]; % 平滑衰减并稳定在 42kW 巡航
t3 = (t_switch2 : dt : t_switch3 - dt)';
P3 = pchip(t3_nodes, p3_nodes, t3);
M3 = ones(size(t3)) * 3;

%% 阶段 4：第二次过渡飞行与下降 (Mode 4)
% 时间段:[2687.6s, 2815.3s) | 准确从 2687.6s 开始
t4_nodes =[t_switch3, t_switch3+10, t_switch3+50, t_switch4];
p4_nodes = [26, 28, 30, 34]; 
t4 = (t_switch3 : dt : t_switch4 - dt)';
P4 = pchip(t4_nodes, p4_nodes, t4);
M4 = ones(size(t4)) * 4;

%% 阶段 5：着陆与悬停 (Mode 5)
% 时间段: [2815.3s, 3000s] | 准确从 2815.3s 开始，包含最终的 3000.0s
t5_nodes =[t_switch4, t_switch4+20, t_switch4+50, t_switch4+100, t_end];
p5_nodes =[122, 112, 110, 108, 112];
t5 = (t_switch4 : dt : t_end)';
P5 = pchip(t5_nodes, p5_nodes, t5);
M5 = ones(size(t5)) * 5;

%% 合并所有数据 (严格单调递增时间轴，无重复帧)
time =[t1; t2; t3; t4; t5];
P_req_ori =[P1; P2; P3; P4; P5];
Flight_Mode =[M1; M2; M3; M4; M5];

%% ================= 在命令窗口输出切换时刻日志 =================
fprintf('\n=========================================================\n');
fprintf('    ✈️ 倾转旋翼飞行器飞行剖面生成完毕 (3000s 目标版) ✈️\n');
fprintf('=========================================================\n');
fprintf('总仿真时长 : %.1f 秒 | 总数据点数: %d\n', time(end), length(time));
fprintf('---------------------------------------------------------\n');
fprintf('【模式切换时刻表】(基于真实过渡时长，切换时刻归属新模式)\n');
fprintf('▶ 时刻 %7.1f s : Mode 1 (起飞阶段) -> Mode 2 (首次过渡)\n', t_switch1);
fprintf('▶ 时刻 %7.1f s : Mode 2 (首次过渡) -> Mode 3 (前飞巡航)\n', t_switch2);
fprintf('▶ 时刻 %7.1f s : Mode 3 (前飞巡航) -> Mode 4 (二次过渡)\n', t_switch3);
fprintf('▶ 时刻 %7.1f s : Mode 4 (二次过渡) -> Mode 5 (悬停着陆)\n', t_switch4);
fprintf('=========================================================\n\n');

%% 保存为 .mat 文件 (方便能量管理 Simulink 查表使用)
save('TiltRotor_Profile_3000s.mat', 'time', 'P_req_ori', 'Flight_Mode');

%% 绘制高质量验证图
fig = figure('Name', '3000s Flight Profile', 'Color', 'w', 'Position',[100, 100, 900, 450]);

% 左侧 Y 轴：功率
yyaxis left
h1 = plot(time, P_req_ori, '-', 'LineWidth', 2.0, 'Color',[0 0.4470 0.7410]); 
ylabel('Power \it{P_{req\_ori}} \rm{(kW)}', 'FontName', 'Times New Roman', 'FontSize', 12);
ax = gca; ax.YColor =[0 0.4470 0.7410]; 
ylim([0, 140]);

% 右侧 Y 轴：飞行模式
yyaxis right
h2 = stairs(time, Flight_Mode, '-', 'LineWidth', 2.0, 'Color',[0.8500 0.3250 0.0980]); 
ylabel('Flight Mode', 'FontName', 'Times New Roman', 'FontSize', 12);
ax.YColor =[0.8500 0.3250 0.0980];
ylim([0, 6]); yticks(1:5);

% X 轴与图表修饰
xlabel('Time (s)', 'FontName', 'Times New Roman', 'FontSize', 12);
xlim([0, 3000]);

% 添加垂直虚线标记精确的切换时刻
xlines_pos =[t_switch1, t_switch2, t_switch3, t_switch4];
for i = 1:length(xlines_pos)
    xline(xlines_pos(i), '--k', 'LineWidth', 1.2, 'Alpha', 0.5);
end

lgd = legend([h1, h2], {'Power \it{P_{req\_ori}}', 'Flight Mode'}, 'Location', 'best');
set(lgd, 'FontName', 'Times New Roman', 'FontSize', 11, 'Box', 'off');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 11, 'TickDir', 'in', 'LineWidth', 1.0, 'XMinorTick', 'on');
box on; grid on; ax.GridAlpha = 0.2;
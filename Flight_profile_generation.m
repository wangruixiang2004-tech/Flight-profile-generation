%% 倾转旋翼飞行器功率剖面生成器 (Tilt-Rotor Power Profile Generator)
clear; clc; close all;

% 设置采样频率 (10Hz)
dt = 0.1; 

%% 阶段 1：起飞与垂直爬升 (Mode 1)
% 持续时间: 0 - 250s | 功率: 约 120 kW
t1_nodes =[0, 50, 100, 200, 250];
p1_nodes =[120, 122, 125, 118, 118]; % 模拟起飞初期的功率波动
t1 = (0 : dt : 250)';
P1 = pchip(t1_nodes, p1_nodes, t1);
M1 = ones(size(t1)) * 1;

%% 阶段 2：第一次过渡飞行 (Mode 2)
% 持续时间: 250 - 350s | 功率: 剧烈波动，对应旋翼倾转过程
t2_nodes =[250+dt, 260, 270, 280, 310, 350];
p2_nodes =[42, 20, 35, 93, 75, 70]; % 完美复刻图片中骤降后拉高的形状
t2 = (250+dt : dt : 350)';
P2 = pchip(t2_nodes, p2_nodes, t2);
M2 = ones(size(t2)) * 2;

%% 阶段 3：前飞巡航 (Mode 3) 
% 持续时间: 350 - 2350s (精准控制为 2000 秒) | 功率: 稳态 42 kW
t3_nodes =[350+dt, 450, 600, 2350];
p3_nodes =[70, 45, 42, 42]; % 从过渡段平滑衰减并稳定在 42kW
t3 = (350+dt : dt : 2350)';
P3 = pchip(t3_nodes, p3_nodes, t3);
M3 = ones(size(t3)) * 3;

%% 阶段 4：第二次过渡飞行与下降 (Mode 4)
% 持续时间: 2350 - 2750s | 功率: 骤降后缓慢爬升
t4_nodes =[2350+dt, 2360, 2500, 2750];
p4_nodes =[26, 28, 30, 34]; 
t4 = (2350+dt : dt : 2750)';
P4 = pchip(t4_nodes, p4_nodes, t4);
M4 = ones(size(t4)) * 4;

%% 阶段 5：着陆与悬停 (Mode 5)
% 持续时间: 2750 - 2950s | 功率: 重新恢复到 120 kW 级别
t5_nodes =[2750+dt, 2760, 2800, 2900, 2950];
p5_nodes =[122, 112, 110, 108, 112];
t5 = (2750+dt : dt : 2950)';
P5 = pchip(t5_nodes, p5_nodes, t5);
M5 = ones(size(t5)) * 5;

%% 合并所有数据
time =[t1; t2; t3; t4; t5];
P_req_ori =[P1; P2; P3; P4; P5];
Flight_Mode =[M1; M2; M3; M4; M5];

% (可选) 增加轻微的白噪声，让功率曲线看起来更像是真实的传感器数据
% P_req_ori = P_req_ori + 0.15 * randn(size(P_req_ori));

%% 保存为 .mat 文件 (方便能量管理 Simulink 查表使用)
% 注：此处功率 P_req_ori 的单位为 kW，以契合你 120 和 42 的数值
save('TiltRotor_Profile.mat', 'time', 'P_req_ori', 'Flight_Mode');
fprintf('成功生成倾转旋翼飞行剖面文件：TiltRotor_Profile.mat\n');
fprintf('总时长: %.1f 秒，巡航时长: 2000 秒，包含 5 个阶段。\n', time(end));

%% 绘制验证图 (复刻你提供的 SCI 风格双轴图)
fig = figure('Name', 'Generated Flight Profile', 'Color', 'w', 'Position',[100, 100, 800, 400]);

% 左轴：功率
yyaxis left
h1 = plot(time, P_req_ori, '-', 'LineWidth', 2.0, 'Color',[0 0.4470 0.7410]); 
ylabel('Power \it{P_{req\_ori}} \rm{(kW)}', 'FontName', 'Times New Roman', 'FontSize', 12);
ax = gca; ax.YColor =[0 0.4470 0.7410]; 
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
lgd = legend([h1, h2], {'Power \it{P_{req\_ori}}', 'Flight Mode'}, 'Location', 'best');
set(lgd, 'FontName', 'Times New Roman', 'FontSize', 10, 'Box', 'off');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 10, 'TickDir', 'in', 'LineWidth', 1.0, 'XMinorTick', 'on');
box on; grid on; ax.GridAlpha = 0.2;
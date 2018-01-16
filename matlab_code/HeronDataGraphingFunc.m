function [ output_args ] = HeronDataGraphingFunc( inp_data, save_name_prefix, save_figs_flag )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%Initialize
%     fig_num = 0;
    SaveNames = {};

%Pressures
%     fig_num = fig_num+1; figure(fig_num); hold on;
    fig = figure(); hold on;
    plot(inp_data.Inlet.times,inp_data.Inlet.P);
    plot(inp_data.Outlet.times,inp_data.Outlet.P);
    xlabel('time (sec)')
    ylabel('Pressure (Pa)')
    legend('Inlet','Outlet')
    if save_figs_flag
        FullSaveName = [save_name_prefix '_pressures'];
        saveas(fig,FullSaveName,'jpg')
%         SaveNames{fig_num} = FullSaveName; %keep list of saved files for adding to powerpoint
    end
%Flowrates
%     fig_num = fig_num+1; figure(fig_num); hold on;
    fig = figure(); hold on;
    plot(inp_data.flowmeter.times,inp_data.flowmeter.mdot);
    xlabel('time (sec)')
    ylabel('Flow Rate (kg/s)')
    if save_figs_flag
        FullSaveName = [save_name_prefix '_flowrate'];
        saveas(fig(),FullSaveName,'jpg')
%         SaveNames{fig_num} = FullSaveName; %keep list of saved files for adding to powerpoint
    end
%Power
%     fig_num = fig_num+1; figure(fig_num); hold on;
    fig = figure(); hold on;
    plot(inp_data.motor.times,inp_data.motor.brake_power);
    plot(inp_data.turbine.times,inp_data.turbine.ind_power);
    xlabel('time (sec)')
    ylabel('power (W)')
    legend('brake power','indicated power')
    if save_figs_flag
        FullSaveName = [save_name_prefix '_powers'];
        saveas(fig,FullSaveName,'jpg')
%         SaveNames{fig_num} = FullSaveName; %keep list of saved files for adding to powerpoint
    end

end


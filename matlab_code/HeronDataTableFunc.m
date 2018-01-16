function [ results_array, col_headers ] = HeronDataTableFunc( inp_data, data_file_name, results_array)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%Initialize
    col = 1; %initialize to start at column 1
    [rows, ~] = size(results_array);
    tbl_ind = rows+1;
    data_window_mask = [inp_data.Inlet.times>7 & inp_data.Inlet.times<9];
    no_flow_window_mask = [inp_data.Inlet.times<3];

%% Create data table
    %Headers get added each time but easier to follow this way
    col_headers{1,col} = 'Exp No';
        results_array{tbl_ind,col} = tbl_ind;
        col = col+1;
    col_headers{1,col} = 'Data File';
        results_array{tbl_ind,col} = data_file_name;
        col = col+1;

    col_headers{1,col} = 'exp RPM';
        results_array{tbl_ind,col} = round(mean(inp_data.motor.RPM(no_flow_window_mask)),0);
        col = col+1;
        
    col_headers{1,col} = 'exp no flow brake power (W)';
        results_array{tbl_ind,col} = round(mean(inp_data.motor.brake_power(no_flow_window_mask)),2);
        col = col+1;
    col_headers{1,col} = 'exp no flow ind power (W)';
        results_array{tbl_ind,col} = round(mean(inp_data.turbine.ind_power(no_flow_window_mask)),2);
        col = col+1;
    col_headers{1,col} = 'exp no flow torque (Nm)';
        results_array{tbl_ind,col} = round(mean(inp_data.motor.torque(no_flow_window_mask)),2);
        col = col+1;
        
    col_headers{1,col} = 'exp brake power (W)';
        results_array{tbl_ind,col} = round(mean(inp_data.motor.brake_power(data_window_mask)),2);
        col = col+1;
    col_headers{1,col} = 'exp ind power (W)';
        results_array{tbl_ind,col} = round(mean(inp_data.turbine.ind_power(data_window_mask)),2);
        col = col+1;
   col_headers{1,col} = 'exp mass flow rate (kg/s)';
        results_array{tbl_ind,col} = round(mean(inp_data.flowmeter.mdot(data_window_mask)),4);
        col = col+1;
    col_headers{1,col} = 'exp torque (Nm)';
        results_array{tbl_ind,col} = round(mean(inp_data.motor.torque(data_window_mask)),2);
        col = col+1;
        
        
    %Inlet Conditions
    col_headers{1,col} = 'exp P Inlet (Pa)';
        results_array{tbl_ind,col} = round(mean(inp_data.Inlet.P(data_window_mask)),0);
        col = col+1;
    col_headers{1,col} = 'exp T Inlet (K)';
        results_array{tbl_ind,col} = round(mean(inp_data.Inlet.T(data_window_mask)),1);
        col = col+1;
    col_headers{1,col} = 'exp h Inlet (J/kg)';
        results_array{tbl_ind,col} = round(mean(inp_data.Inlet.h(data_window_mask)),0);
        col = col+1;
    col_headers{1,col} = 'exp s Inlet (J/kg-K)';
        results_array{tbl_ind,col} = round(mean(inp_data.Inlet.s(data_window_mask)),0);
        col = col+1;

    %Outlet conditions
    col_headers{1,col} = 'exp P Outlet (Pa)';
        results_array{tbl_ind,col} = round(mean(inp_data.Outlet.P(data_window_mask)),0);
        col = col+1;
    col_headers{1,col} = 'exp T Outlet (K)';
        results_array{tbl_ind,col} = round(mean(inp_data.Outlet.T(data_window_mask)),1);
        col = col+1;
    col_headers{1,col} = 'exp h Outlet (J/kg)';
        results_array{tbl_ind,col} = round(mean(inp_data.Outlet.h(data_window_mask)),0);
        col = col+1;
    col_headers{1,col} = 'exp s Outlet (J/kg-K)';
        results_array{tbl_ind,col} = round(mean(inp_data.Outlet.s(data_window_mask)),0);
        col = col+1;
        
    %housing conditions
    col_headers{1,col} = 'exp P housing (Pa)';
        results_array{tbl_ind,col} = round(mean(inp_data.housing.P(data_window_mask)),0);
        col = col+1;
    col_headers{1,col} = 'exp T housing (K)';
        results_array{tbl_ind,col} = round(mean(inp_data.housing.T(data_window_mask)),1);
        col = col+1;
    col_headers{1,col} = 'exp h housing (J/kg)';
        results_array{tbl_ind,col} = round(mean(inp_data.housing.h(data_window_mask)),0);
        col = col+1;
    col_headers{1,col} = 'exp s housing (J/kg-K)';
        results_array{tbl_ind,col} = round(mean(inp_data.housing.s(data_window_mask)),0);
        col = col+1;
        
    %Isentropic outlet conditions
    fluid = 'air.ppf';
    mdot = mean(inp_data.flowmeter.mdot(data_window_mask));
    P_inlet = mean(inp_data.Inlet.P(data_window_mask));
    h_inlet = mean(inp_data.Inlet.h(data_window_mask));
    s_inlet = mean(inp_data.Inlet.s(data_window_mask));
    
    P_outlet = mean(inp_data.Outlet.P(data_window_mask));
    s_outlet_isen = mean(inp_data.Outlet.s_isen(data_window_mask));
    h_outlet_isen = mean(inp_data.Outlet.h_isen(data_window_mask));
    T_outlet_isen = mean(inp_data.Outlet.T_isen(data_window_mask));
    h_outlet = mean(inp_data.Outlet.h(data_window_mask));
    
    isen_power = (h_inlet - h_outlet_isen)*mdot;
    isen_efficiency = (h_inlet - h_outlet) / (h_inlet - h_outlet_isen);
    
    col_headers{1,col} = 'isentropic power (W)';
        results_array{tbl_ind,col} = round(mean(isen_power),0);
        col = col+1;
    col_headers{1,col} = 'isentropic efficiency';
        results_array{tbl_ind,col} = round(mean(isen_efficiency),4);
        col = col+1;
        
    col_headers{1,col} = 'isen P Outlet (Pa)';
        results_array{tbl_ind,col} = round(P_outlet,0);
        col = col+1;
    col_headers{1,col} = 'isen T Outlet (K)';
        results_array{tbl_ind,col} = round(T_outlet_isen,1);
        col = col+1;
    col_headers{1,col} = 'isen h Outlet (J/kg)';
        results_array{tbl_ind,col} = round(h_outlet_isen,0);
        col = col+1;
    col_headers{1,col} = 'isen s Outlet (J/kg-K)';
        results_array{tbl_ind,col} = round(s_outlet_isen,0);
        col = col+1;
    
    %momentum balance
    mdot = mean(inp_data.flowmeter.mdot(data_window_mask));
    rho_fluid = mean(inp_data.housing.rho(data_window_mask));
    area_nozzle = 0.01*0.01;  %area of a single nozzle in m^2
    N_nozzles = 4;  %number of nozzles
    theta_nozzle = 10*pi/180;  %angle of nozzle relative to perpendicular
    R_turbine = 0.25;  %radius of turbine in m
    
    omega_turbine = inp_data.motor.RPM_avg*(2*pi/60);   %radial velocity of turbine (rad/s)
    vel_fluid_rel_nozzle = mdot/(rho_fluid*area_nozzle*N_nozzles);  %velocity of turbine relative to nozzle
    vel_nozzle = omega_turbine*R_turbine;  %velocity in m/s
    vel_fluid = vel_fluid_rel_nozzle*cos(theta_nozzle) - vel_nozzle;
    torque = vel_fluid^2*R_turbine*rho_fluid*area_nozzle*N_nozzles;
    
    col_headers{1,col} = 'exp fluid velocity leaving nozzle (m/s)';
        results_array{tbl_ind,col} = round(vel_fluid_rel_nozzle,2);
        col = col+1;
    col_headers{1,col} = 'exp fluid velocity relative to stationary (m/s) [angle accounted for]';
        results_array{tbl_ind,col} = round(vel_fluid,2);
        col = col+1;
    col_headers{1,col} = 'exp calculated fluid torque (Nm)';
        results_array{tbl_ind,col} = round(torque,2);
        col = col+1;


end


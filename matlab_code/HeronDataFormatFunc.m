function [ output_args ] = HeronDataFormatFunc( inputs )
%HeronDataFormatFunc: Takes heron data in cell array format and converts to
%more useful format
%   Inputs to this function are the outputs from HeronDataExtractionFunc.
%   The data is relabeled to be more descriptive and other values are
%   calculated.

%% Settings and inputs
    fluid = 'air.ppf';
    P_ambient = 101325;  %assumed ambient pressure in Pa
    
%% Calculate State Points
%rename variables to be more descriptive, convert units and calculate fluid
%conditions
    %turbine inlet
    results.Inlet.times = inputs.rPHUT2.times;
    results.Inlet.P = inputs.rPHUT2.vals * 6894.76 + P_ambient; %convert from psig to Pa absolute
    results.Inlet.T = inputs.rTHUT5.vals + 273.15;              %convert from C to K
    for x = 1:length(results.Inlet.times)
        results.Inlet.rho(x,1) = refpropm('D','T',results.Inlet.T(x,1),'P',results.Inlet.P(x,1)/1000,fluid); 
        results.Inlet.h(x,1) = refpropm('H','T',results.Inlet.T(x,1),'P',results.Inlet.P(x,1)/1000,fluid);         
        results.Inlet.s(x,1) = refpropm('S','T',results.Inlet.T(x,1),'P',results.Inlet.P(x,1)/1000,fluid); 
    end

    %turbine outlet
    results.Outlet.times = inputs.rPHUT4.times;
    results.Outlet.P = inputs.rPHUT4.vals * 6894.76 + P_ambient; %convert from psig to Pa absolute
    results.Outlet.T = inputs.rTHUT3.vals + 273.15;              %convert from C to K
    for x = 1:length(results.Outlet.times)
        results.Outlet.rho(x,1) = refpropm('D','T',results.Outlet.T(x,1),'P',results.Outlet.P(x,1)/1000,fluid); 
        results.Outlet.h(x,1) = refpropm('H','T',results.Outlet.T(x,1),'P',results.Outlet.P(x,1)/1000,fluid); 
        results.Outlet.s(x,1) = refpropm('S','T',results.Outlet.T(x,1),'P',results.Outlet.P(x,1)/1000,fluid);
        
        results.Outlet.s_isen(x,1) = results.Inlet.s(x,1);
        results.Outlet.h_isen(x,1) = refpropm('H','P',results.Outlet.P(x,1)/1000,'S',results.Outlet.s_isen(x,1),fluid);
        results.Outlet.T_isen(x,1) = refpropm('T','P',results.Outlet.P(x,1)/1000,'S',results.Outlet.s_isen(x,1),fluid);
    end
    
    %at flow meter
    results.flowmeter.times = inputs.rPLPFlowmeter.times;
    results.flowmeter.P = inputs.rPLPFlowmeter.vals * 6894.76 + P_ambient; %convert from psig to Pa absolute
    results.flowmeter.T = inputs.rTLPFlowmeter.vals + 273.15;              %convert from C to K
    for x = 1:length(results.Outlet.times)
        results.flowmeter.rho(x,1) = refpropm('D','T',results.flowmeter.T(x,1),'P',results.flowmeter.P(x,1)/1000,fluid); 
        results.flowmeter.h(x,1) = refpropm('H','T',results.flowmeter.T(x,1),'P',results.flowmeter.P(x,1)/1000,fluid); 
        results.flowmeter.s(x,1) = refpropm('S','T',results.flowmeter.T(x,1),'P',results.flowmeter.P(x,1)/1000,fluid);
    end
    vol_flowrate = inputs.rFMLPManifoldLPS.vals * 0.001;   %convert from L/s to m^3/s
    results.flowmeter.mdot = vol_flowrate .* results.flowmeter.rho;
    
    %In housing
    results.housing.times = inputs.rTHUT2.times;
    results.housing.P_top = inputs.rPHUT1.vals * 6894.76 + P_ambient; %convert from psig to Pa absolute
    results.housing.P_R = inputs.rPHUT5.vals * 6894.76 + P_ambient; %convert from psig to Pa absolute
    results.housing.P_L = inputs.rPHUT3.vals * 6894.76 + P_ambient; %convert from psig to Pa absolute
    results.housing.T_top = inputs.rTHUT2.vals + 273.15; %convert from C to K
    results.housing.T_R = inputs.rTHUT4.vals + 273.15; %convert from C to K
    results.housing.T_L = inputs.rTHUT6.vals + 273.15; %convert from C to K
    
    results.housing.P = mean([results.housing.P_top';results.housing.P_R';results.housing.P_L'])';
    results.housing.T = mean([results.housing.T_top';results.housing.T_R';results.housing.T_L'])';
%     disp(results.housing.P_top)
%     disp(results.housing.P)
    for x = 1:length(results.housing.times)
        results.housing.rho(x,1) = refpropm('D','T',results.housing.T(x,1),'P',results.housing.P(x,1)/1000,fluid); 
        results.housing.h(x,1) = refpropm('H','T',results.housing.T(x,1),'P',results.housing.P(x,1)/1000,fluid); 
        results.housing.s(x,1) = refpropm('S','T',results.housing.T(x,1),'P',results.housing.P(x,1)/1000,fluid);
    end
    
    %Machine Power
    results.motor.times = inputs.rTorqueHUTAvg_1k.times;
    results.motor.torque = inputs.rTorque_HT2.vals;
    results.motor.RPM(1:length(results.motor.times),1) = inputs.rpm;
    results.motor.brake_power = results.motor.torque .* results.motor.RPM.*(2*pi/60);
    results.motor.RPM_avg = inputs.rpm;
    
    %Turbine Power
    results.turbine.times = results.Inlet.times;
    results.turbine.ind_power = (results.Inlet.h - results.Outlet.h).*results.flowmeter.mdot;

    

%% Return results
    output_args = results;

end


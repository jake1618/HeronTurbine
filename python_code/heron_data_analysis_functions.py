"""
Created on Fri Jan 12 12:31:19 2018

@author: Tyler
"""

## Import Needed Functions
import pandas as pd
import numpy as np
import CoolProp.CoolProp as CP
import matplotlib.pyplot as plt


## Function Library
def HeronDataExtractionFunc(FilePath):
    """
    This function takes the full path to a csv file, extracts the data and returns
    a dictionary of dictionaries. The high level dictionaries are the names of
    the sensors in the csv file and each entry has 'times' and 'vals' fields
    
    ex: results_dict['sensor_name']['times']
    """    
    
    ## first pull data into a Pandas DataFrame and filter b/c this is easiest
    temp_df = pd.DataFrame()
    temp_df = pd.read_csv(FilePath, sep='\t', skiprows=6)
    # Get rid of extra info in each column (header stuff)
    temp_df.drop(temp_df.index[range(0, 13)], inplace=True)
    # delete last two rows (these have excess info)
    temp_df.drop(temp_df.index[-2:], inplace=True)
    # renumber indices
    temp_df.reset_index(inplace=True, drop=True)

    
    ## Convert to dictionaries
    #Go through each data column and create a dictionary entry w/ time and vals
    #every other column in dataframe is vals and the preceeding column is times
    col_names = temp_df.columns
    results_dict = {}
    for col in range(0,len(col_names)-1,2):  #go through every other column
        #note that values in dataframe are strings and must be converted to numbers using 'to_numeric'
        #some sensors are 10k and others are 1k, the 'coerce' option converts empty values in 1k data
        #to NaN and then they are filtered out using the isnan step later
        times = pd.to_numeric(temp_df[col_names[col]].values, errors='coerce')/1000.0  #convert to seconds from milliseconds
        vals = pd.to_numeric(temp_df[col_names[col+1]].values, errors='coerce')
        sensor_dict = {}
        sensor_dict['vals'] = vals[~np.isnan(vals)]
        sensor_dict['times'] = times[~np.isnan(times)]
        results_dict[col_names[col+1]] = sensor_dict
                    
    #pull rpm from data file name and add to results dictionary
    #find 'rpm' in the name string and pull out the number before it
    rpm_start = FilePath.find('rpm')-5
    rpm_end = FilePath.find('rpm')-1
    if FilePath.find('rpm') == -1:  #this is case if rpm not in file name
        results_dict['rpm'] = 0.0
    else:
        results_dict['rpm'] = pd.to_numeric(FilePath[rpm_start:rpm_end])
        
    #Add full filepath to results dictionary
    results_dict['data_location'] = FilePath
        
    
    return results_dict


def HeronDataFormatFunc(inputs):
    """
    This function takes raw data with sensor names as output by HeronDataExtractionFunc()
    and organizes it into easier to understand format
    """
    
    ## Settings and inputs
    fluid = 'air'
    P_ambient = 101325  #assumed ambient pressure in Pa

        
    ## Calculate State Points
    #rename variables to be more descriptive, convert units and calculate fluid
    #conditions
    
    #turbine inlet
    Inlet = {}  #create empty dictionary
    Inlet['times'] = inputs['rPHUT2']['times']
    Inlet['P'] = inputs['rPHUT2']['vals'] * 6894.76 + P_ambient #convert from psig to Pa absolute
    Inlet['T'] = inputs['rTHUT5']['vals'] + 273.15    #convert from C to K            
    Inlet['rho'] = CP.PropsSI("D", "T", Inlet['T'], "P",  Inlet['P'], fluid)
    Inlet['h'] = CP.PropsSI("H", "T", Inlet['T'], "P",  Inlet['P'], fluid)
    Inlet['s'] = CP.PropsSI("S", "T", Inlet['T'], "P",  Inlet['P'], fluid)
    
    #turbine outlet
    Outlet = {}
    Outlet['times'] = inputs['rPHUT4']['times']
    Outlet['P'] = inputs['rPHUT4']['vals'] * 6894.76 + P_ambient #convert from psig to Pa absolute
    Outlet['T'] = inputs['rTHUT3']['vals'] + 273.15    #convert from C to K            
    Outlet['rho'] = CP.PropsSI("D", "T", Outlet['T'], "P", Outlet['P'], fluid)
    Outlet['h'] = CP.PropsSI("H", "T", Outlet['T'], "P", Outlet['P'], fluid)
    Outlet['s'] = CP.PropsSI("S", "T", Outlet['T'], "P", Outlet['P'], fluid)
    
    Outlet['s_isen'] = Inlet['s']
    try:  #if there is no data at some of the time stamps this doesn't work right
        Outlet['h_isen'] = CP.PropsSI("H", "P", Outlet['P'], "S", Outlet['s_isen'], fluid)
        Outlet['T_isen'] = CP.PropsSI("T", "P", Outlet['P'], "S", Outlet['s_isen'], fluid)
    except:  #fill in zeros so it has values and doesn't trigger more errors later
        Outlet['h_isen'] = np.zeros(len(Outlet['P']))
        Outlet['T_isen'] = np.zeros(len(Outlet['P']))
    
    #at flowmeter
    flowmeter = {}
    flowmeter['times'] = inputs['rPLPFlowmeter']['times']
    flowmeter['P'] = inputs['rPLPFlowmeter']['vals'] * 6894.76 + P_ambient #convert from psig to Pa absolute
    flowmeter['T'] = inputs['rTLPFlowmeter']['vals'] + 273.15    #convert from C to K            
    flowmeter['rho'] = CP.PropsSI("D", "T", flowmeter['T'], "P", flowmeter['P'], fluid)
    flowmeter['h'] = CP.PropsSI("H", "T", flowmeter['T'], "P", flowmeter['P'], fluid)
    flowmeter['s'] = CP.PropsSI("S", "T", flowmeter['T'], "P", flowmeter['P'], fluid)
    vol_flowrate = inputs['rFMLPManifoldLPS']['vals'] * 0.001   #convert from L/s to m^3/s
    flowmeter['mdot'] = vol_flowrate * flowmeter['rho']
    
    #In housing
    housing = {}
    housing['times'] = inputs['rTHUT2']['times']
    housing['P_top'] = inputs['rPHUT1']['vals'] * 6894.76 + P_ambient  #convert from psig to Pa absolute
    housing['P_R'] = inputs['rPHUT5']['vals'] * 6894.76 + P_ambient  #convert from psig to Pa absolute
    housing['P_L'] = inputs['rPHUT3']['vals'] * 6894.76 + P_ambient  #convert from psig to Pa absolute
    housing['T_top'] = inputs['rTHUT2']['vals'] + 273.15 #convert from C to K
    housing['T_R'] = inputs['rTHUT4']['vals'] + 273.15 #convert from C to K
    housing['T_L'] = inputs['rTHUT6']['vals'] + 273.15 #convert from C to K
    
    housing['P'] = np.mean([housing['P_top'],housing['P_R'],housing['P_L']],axis=0)
    housing['T'] = np.mean([housing['T_top'],housing['T_R'],housing['T_L']],axis=0)
    housing['rho'] = CP.PropsSI("D", "T", housing['T'], "P", housing['P'], fluid)
    housing['h'] = CP.PropsSI("H", "T", housing['T'], "P", housing['P'], fluid)
    housing['s'] = CP.PropsSI("S", "T", housing['T'], "P", housing['P'], fluid)
    
    #Machine Power
    motor = {}
    motor['times'] = inputs['rTorque_HT2']['times']
    motor['torque'] = inputs['rTorque_HT2']['vals']
    motor['RPM'] = np.ones(len(motor['times']))*inputs['rpm']
    motor['brake_power'] = motor['torque'] * motor['RPM']*(2.0*np.pi/60.0)
    motor['RPM_avg'] = inputs['rpm']    
    
    #Turbine Power
    turbine = {}
    turbine['times'] = Inlet['times']
    turbine['ind_power'] = (Inlet['h'] - Outlet['h'])*flowmeter['mdot']           
    
    
    ## Combine all sub dictionaries into final results
    format_results = {'Inlet':Inlet,'Outlet':Outlet,'flowmeter':flowmeter,
                      'housing':housing,'motor':motor,'turbine':turbine}
    
    return format_results

def HeronDataTableFunc(inp_data, data_file_name, results_array):
    
    ## Initialize
    col_headers = []  #list of col headers
    results_row = []  #list of values for this data set
    
#    tbl_ind = len(results_array)+1
    data_window_mask = [(inp_data['Inlet']['times']>7) & (inp_data['Inlet']['times']<9)]
    no_flow_window_mask = [inp_data['Inlet']['times']<3]
    
    
    ## Create data table
    #Headers get added each time but easier to follow this way
#    col_headers.append('Exp No')
#    results_row.append(tbl_ind)
    
    col_headers.append('Data File')
    results_row.append(data_file_name)
    
    col_headers.append('exp RPM')
    results_row.append(np.mean(inp_data['motor']['RPM_avg']))
    
    #No Flow Power
    col_headers.append('exp no flow brake power (W)')
    results_row.append(round(np.mean(inp_data['motor']['brake_power'][no_flow_window_mask]),2))
    col_headers.append('exp no flow ind power (W)')
    results_row.append(round(np.mean(inp_data['turbine']['ind_power'][no_flow_window_mask]),2))
    col_headers.append('exp no flow torque (Nm)')
    results_row.append(round(np.mean(inp_data['motor']['torque'][no_flow_window_mask]),2))
    
    #Power w/ flow
    col_headers.append('exp flow brake power (W)')
    results_row.append(round(np.mean(inp_data['motor']['brake_power'][data_window_mask]),2) )  
    col_headers.append('exp flow ind power (W)')
    results_row.append(round(np.mean(inp_data['turbine']['ind_power'][data_window_mask]),2) ) 
    col_headers.append('exp flow torque (Nm)')
    results_row.append(round(np.mean(inp_data['motor']['torque'][data_window_mask]),2))
    col_headers.append('exp flow rate (kg/s)')
    results_row.append(round(np.mean(inp_data['flowmeter']['mdot'][data_window_mask]),4))

    #Inlet Conditions
    col_headers.append('exp P Inlet (Pa)')
    results_row.append(round(np.mean(inp_data['Inlet']['P'][data_window_mask]),0))
    col_headers.append('exp T Inlet (K)')
    results_row.append(round(np.mean(inp_data['Inlet']['T'][data_window_mask]),1))
    col_headers.append('exp h Inlet (J/kg)')
    results_row.append(round(np.mean(inp_data['Inlet']['h'][data_window_mask]),0)) 
    col_headers.append('exp s Inlet (J/kg-K)')
    results_row.append(round(np.mean(inp_data['Inlet']['s'][data_window_mask]),0))
    
    #Outlet Conditions
    col_headers.append('exp P Outlet (Pa)')
    results_row.append(round(np.mean(inp_data['Outlet']['P'][data_window_mask]),0))  
    col_headers.append('exp T Outlet (K)')
    results_row.append(round(np.mean(inp_data['Outlet']['T'][data_window_mask]),1))
    col_headers.append('exp h Outlet (J/kg)')
    results_row.append(round(np.mean(inp_data['Outlet']['h'][data_window_mask]),0))
    col_headers.append('exp s Outlet (J/kg-K)')
    results_row.append(round(np.mean(inp_data['Outlet']['s'][data_window_mask]),0))
    
    #Housing Conditions
    col_headers.append('exp P housing (Pa)')
    results_row.append(round(np.mean(inp_data['housing']['P'][data_window_mask]),0))
    col_headers.append('exp T housing (K)')
    results_row.append(round(np.mean(inp_data['housing']['T'][data_window_mask]),1))
    col_headers.append('exp h housing (J/kg)')
    results_row.append(round(np.mean(inp_data['housing']['h'][data_window_mask]),0))
    col_headers.append('exp s housing (J/kg-K)')
    results_row.append(round(np.mean(inp_data['housing']['s'][data_window_mask]),0))
    
    #Isentropic Outlet Conditions
    mdot = np.mean(inp_data['flowmeter']['mdot'][data_window_mask])
    P_inlet = np.mean(inp_data['Inlet']['P'][data_window_mask])
    h_inlet = np.mean(inp_data['Inlet']['h'][data_window_mask])
    s_inlet = np.mean(inp_data['Inlet']['s'][data_window_mask])
    
    P_outlet = np.mean(inp_data['Outlet']['P'][data_window_mask])
    s_outlet_isen = np.mean(inp_data['Outlet']['s_isen'][data_window_mask])
    h_outlet_isen = np.mean(inp_data['Outlet']['h_isen'][data_window_mask])
    T_outlet_isen = np.mean(inp_data['Outlet']['T_isen'][data_window_mask])
    h_outlet = np.mean(inp_data['Outlet']['h'][data_window_mask])
    
    isen_power = (h_inlet - h_outlet_isen)*mdot
    isen_efficiency = (h_inlet - h_outlet) / (h_inlet - h_outlet_isen)
    
    col_headers.append('isentropic power (W)')
    results_row.append(round(np.mean(isen_power),0))
    col_headers.append('isentropic efficiency')
    results_row.append(round(np.mean(isen_efficiency),4))
    
    col_headers.append('isen P Outlet (Pa)')
    results_row.append(round(np.mean(P_outlet),0))
    col_headers.append('isen T Outlet (K)')
    results_row.append(round(np.mean(T_outlet_isen),1))
    col_headers.append('isen h Outlet (J/kg)')
    results_row.append(round(np.mean(h_outlet_isen),0))
    col_headers.append('isen s Outlet (J/kg-K)')
    results_row.append(round(np.mean(s_outlet_isen),0))
    
    #Momentum Balance
    mdot = np.mean(inp_data['flowmeter']['mdot'][data_window_mask])
    rho_fluid = np.mean(inp_data['housing']['rho'][data_window_mask])
    area_nozzle = 0.01*0.01  #area of a single nozzle in m^2
    N_nozzles = 4.0  #number of nozzles
    theta_nozzle = 10.0*np.pi/180.0  #angle of nozzle relative to perpendicular
    R_turbine = 0.25  #radius of turbine in m
    
    omega_turbine = inp_data['motor']['RPM_avg']*(2.0*np.pi/60.0)   #radial velocity of turbine (rad/s)
    vel_fluid_rel_nozzle = mdot/(rho_fluid*area_nozzle*N_nozzles)   #velocity of turbine relative to nozzle
    vel_nozzle = omega_turbine*R_turbine   #velocity in m/s
    vel_fluid = vel_fluid_rel_nozzle*np.cos(theta_nozzle) - vel_nozzle
    torque = (vel_fluid**2) *R_turbine*rho_fluid*area_nozzle*N_nozzles
    
    col_headers.append('exp fluid velocity leaving nozzle (m/s)')
    results_row.append(round(np.mean(vel_fluid_rel_nozzle) ,2))
    col_headers.append('exp tangential fluid velocity relative to stationary (m/s)')
    results_row.append(round(np.mean(vel_fluid),2))
    col_headers.append('exp calculated fluid torque (Nm)')
    results_row.append(round(np.mean(torque),2))
    
    
    ## Add results for this row to the total results array as a new row
    if len(results_array)==0:  #this is if we are adding the first row
        OutputArray = results_row
    else:
        OutputArray = np.vstack([results_array,results_row])
    
    
    return OutputArray, col_headers


def HeronDataGraphingFunc(inp_data, save_name_prefix, save_figs_flag):
    
    #Pressures
    fig = plt.figure()
    plt.plot(inp_data['Inlet']['times'],inp_data['Inlet']['P'])
    plt.plot(inp_data['Outlet']['times'],inp_data['Outlet']['P'])
    plt.xlabel('time (sec)')
    plt.ylabel('Pressure (Pa)')
    plt.legend(['Inlet','Outlet'])
    if save_figs_flag:
        plt.savefig(save_name_prefix + '_pressures' + '.png')
        
    #Flowrates
    fig = plt.figure()
    plt.plot(inp_data['flowmeter']['times'],inp_data['flowmeter']['mdot'])
    plt.xlabel('time (sec)')
    plt.ylabel('Flow Rate (kg/s)')
    if save_figs_flag:
        plt.savefig(save_name_prefix + '_flowrate' + '.png')
        
    #Power
    fig = plt.figure()
    plt.plot(inp_data['motor']['times'],inp_data['motor']['brake_power'])
    plt.plot(inp_data['turbine']['times'],inp_data['turbine']['ind_power'])
    plt.xlabel('time (sec)')
    plt.ylabel('Power (W)')
    plt.legend(['brake power','indicated power'])
    if save_figs_flag:
        plt.savefig(save_name_prefix + '_powers' + '.png')

    
    
    
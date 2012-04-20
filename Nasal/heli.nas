
var g_dt = 0;
var gyro_crashed = 0;

aircraft.livery.init("Aircraft/M-XE/Models/Liveries");


var init = func {
	
	
	print("Init Nasal M-XE ...done");
	
	main_loop();
}

# Setup listener call to start update loop once the fdm is initialized
setlistener("sim/signals/fdm-initialized", init);

var reinit = func {
	
	g_dt = 0;
	gyro_crashed = 0;
	#setprop("/controls/rotor/brake", 0);
	print("ReInit Nasal M-XE ...done");
	
}
setlistener("/sim/signals/reinit", reinit);


#var gyrocrashed = func {
#	g_dt = 0;
#	gyro_crashed = 0;
#	setprop("/controls/rotor/brake", 0);
#	
#}
#setlistener("sim/crashed", gyrocrashed);



#main loop
var main_loop = func {

	#stall_horn();
	
	##failures
	#check_g_load();
	#check_vne_flaps();
	#check_vne_structure();
	
	#check_rotor_rpm();
	
	
	check_gear();
	
	settimer(main_loop, 0);
}


#activation de la stall horn
var stall_horn = func{
	var alert = 0;
	var kias = getprop("velocities/airspeed-kt");
	var wow0 = getprop("gear/gear[0]/wow");
	var wow1 = getprop("gear/gear[1]/wow");
	var wow2 = getprop("gear/gear[2]/wow");
	var wow3 = getprop("gear/gear[3]/wow");
	var stall_speed = 30 ;
	if((kias<stall_speed and !wow0 and !wow3 and !wow1 and !wow2) ){
		alert=1;
		#setprop("/sim/messages/copilot","Too slow !!!!!!!!!!!!!");
		#screen.log.write("Too slow !!!", 1, 0, 0);
		
		
	}
	#setprop("/sim/alarms/stall-warning",alert);
	#setprop("/sim/messages/copilot","Too slow !!!!!!!!!!!!!");
}

var check_g_load = func{
	
	#	g_dt = g_dt + 1;
	#}else{
	#	g_dt = 0;
	#}

	#if(g_dt>5){
	
	var g_load = getprop("/accelerations/pilot-g");
	
	if(g_load!=nil and g_load>3.1 )
	{
		#setprop("/controls/flight/wing_destroyed",1);
		#setprop("/sim/sound/crash",1);
		#setprop("/sim/messages/copilot","Too much G load !!!!!!!!!!!!!");
		screen.log.write("Too much G load !!!", 1, 0, 0);
	}
	
	if(g_load!=nil and g_load<0)
	{
		#setprop("/sim/messages/copilot","Negative G load !!!!!!!!!!!!!");
		screen.log.write("Negative G load !!!", 1, 0, 0);
	}
	
}

var	check_vne_structure = func{
	var kias = getprop("velocities/airspeed-kt");
	if(kias!=nil and kias>110){
		#setprop("/sim/sound/crash",1);
		#setprop("/sim/messages/copilot","VNE exceeded !!!!!!!!!!!!!");
		screen.log.write("VNE exceeded !!!", 1, 0, 0);
	}
}

var	check_rotor_rpm = func{
	if (gyro_crashed>0){
		#setprop("/controls/flight/aileron",-1);
		#setprop("/controls/flight/elevator",-1);
		#setprop("/controls/flight/maxreltorque",-1);
		
		
		#setprop("/controls/rotor/brake", 1.0)
	}
	else {
		var rpm = getprop("/rotors/main/rpm");
		if(rpm!=nil and rpm>600){
			#setprop("/sim/sound/crash",1);
			#setprop("/sim/messages/copilot","Rotor overspeed !!!!!!!!!!!!!");
			screen.log.write("Rotor overspeed !!!", 1, 0, 0);
			
			#uncomment when you want to crash
			#gyro_crashed = 1;
		}
		
	}
	
}

		
#gyro.apply_rotor_brake();
var	apply_rotor_brake = func{

	if (gyro_crashed<1){
		interpolate("/controls/rotor/brake", 1.0, 2);
		#print("apply_rotor_brake");
	}
}
		
#gyro.release_rotor_brake();
var	release_rotor_brake = func{

	if (gyro_crashed<1){
		interpolate("/controls/rotor/brake", 0.0, 2);
		#print("release_rotor_brake");
	}
	
}




#set gear weights
# depending on 
# gear touchdown
# airspeed   getprop("velocities/airspeed-kt");
# throttle  /controls/engines/engine/throttle  /controls/engines/engine[0]/throttle
# magnets  /controls/engines/engine[0]/magnetos


var check_gear = func{
	
	var wow0 = getprop("gear/gear[0]/wow");
	var wow1 = getprop("gear/gear[1]/wow");
	var wow2 = getprop("gear/gear[2]/wow");
	var wow3 = getprop("gear/gear[3]/wow");
	
	var throttin =  getprop("controls/engines/engine[0]/throttle"); 
	var kias = getprop("velocities/airspeed-kt");
	var mag = getprop("controls/engines/engine[0]/magnetos");
	
	
	if (kias<15) 
	{
		var wght = 40;
		
		#if engine on, scale weight depending the throttle input
		#important for smooth take off
		if ( (mag>0) ) 
		{
			wght = (throttin* wght);
		
		}
		
		#scale weight depending on airspeed
		#important if sliding forward on the ground
		
		if (kias>0)
		{
		wght = wght* ( 1 - (kias/15) );
		}
		
		if (wow0==1) 
		{
			setprop("/sim/weight[1]/weight-lb",wght);
		}
		else
		{
			setprop("/sim/weight[1]/weight-lb",0);
		
		}
		if (wow1==1) 
		{
			setprop("/sim/weight[2]/weight-lb",wght);
		}
		else
		{
			setprop("/sim/weight[2]/weight-lb",0);
		
		}
		if (wow2==1) 
		{
			setprop("/sim/weight[3]/weight-lb",wght);
		}
		else
		{
			setprop("/sim/weight[3]/weight-lb",0);
		
		}
		if (wow3==1) 
		{
			setprop("/sim/weight[4]/weight-lb",wght);
		}
		else
		{
			setprop("/sim/weight[4]/weight-lb",0);
		
		}
		
		
	}
	else 
	{
		setprop("/sim/weight[1]/weight-lb",0);
		setprop("/sim/weight[2]/weight-lb",0);
		setprop("/sim/weight[3]/weight-lb",0);
		setprop("/sim/weight[4]/weight-lb",0);
	
	}
	
}



#<weight x="0.7900" y="0.7510" z="-0.7518"    mass-prop="/sim/weight[1]/weight-lb"/>
#<weight x="0.7900" y="-0.7510" z="-0.7518"   mass-prop="/sim/weight[2]/weight-lb"/>
#<weight x="-0.8625" y="0.7510" z="-0.7518"   mass-prop="/sim/weight[3]/weight-lb"/>
#<weight x="-0.8625" y="-0.7510" z="-0.7518"  mass-prop="/sim/weight[4]/weight-lb"/>
# from 0 to 30



# vne 110 mph
# 110 mph = 95.5873866 kts
# max rotor = 600 rpm
# engine max 60 kw
# fuel tank 50 lit = kg#
# cruse 70-80 kts
# Max Rate Of Climb: 3 m/s (590 fpm)
# Service Ceiling (estimated): 4000 m (13000 ft)
# Minimum Speed: 40 kmh (22 mph) 19 kts


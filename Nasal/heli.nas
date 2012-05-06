
var g_dt = 0;
var gyro_crashed = 0;
var rotorbrake_message=0;

var def_look_angle= 0;
var look_angle=0;

#aircraft.livery.init("Aircraft/M-XE/Models/Liveries");


var init = func {
	
	
	print("Init Nasal M-XE ...done");
	setprop("/sim/heli-realism-overspeed", 0);
	
	def_look_angle=getprop("sim/current-view/pitch-offset-deg");
	look_angle=0;
	
	main_loop();
}


# Setup listener call to start update loop once the fdm is initialized
setlistener("sim/signals/fdm-initialized", init);

var reinit = func {
	
	g_dt = 0;
	gyro_crashed = 0;
	look_angle=0;
	
	rotorbrake_message=0;
	setprop("/controls/rotor/brake", 0);
	setprop("/sim/heli-realism-overspeed", 0);
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

	
	if ( (gyro_crashed>0) )
	{
		setprop("controls/engines/engine[0]/magnetos",0);
		setprop("/controls/rotor/brake", 1);
		rotorbrake_message=1;
	}
	else
	{
		#stall_horn();
		
		var rotbrk=getprop("/controls/rotor/brake");
		if  ( (rotbrk) and (rotorbrake_message<1) ) 
		{
			screen.log.write("Rotor Brake ON!!!", 1, 0, 0);
			rotorbrake_message=1;
		}
		elsif ( (!rotbrk) and (rotorbrake_message>0) ) 
		{
			screen.log.write("Rotor Brake OFF!!!", 1, 0, 0);
			rotorbrake_message=0;
			
		}
		
		#failures
		if ( getprop("/sim/heli-realism-gforces"))
		{
			check_g_load();
		}
		
		
		# check_vne_flaps();
		# if ( getprop("/sim/heli-realism-airoverspeed"))
		# check_vne_structure();
		
		if ( getprop("/sim/heli-realism-rpmoverspeed"))
		{
			check_rotor_rpm();
		}
		
	
	}
	
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
	
	var g_load = getprop("/accelerations/pilot-g");
	
	var wow0 = getprop("gear/gear[0]/wow");
	var wow1 = getprop("gear/gear[1]/wow");
	var wow2 = getprop("gear/gear[2]/wow");
	var wow3 = getprop("gear/gear[3]/wow");
	
	if( !wow0 and !wow3 and !wow1 and !wow2) 
	{
		
		if (gyro_crashed>0)
		{
			#ignore
		}
		elsif (g_load!=nil and g_load>3.5)
		{
			#setprop("/controls/flight/wing_destroyed",1);
			#setprop("/sim/sound/crash",1);
			#setprop("/sim/messages/copilot","Too much G load !!!!!!!!!!!!!");
			#screen.log.write("Too much G load !!!", 1, 0, 0);
			blade_fail();
		}
		elsif (g_load!=nil and g_load<-1.5)
		{
			#setprop("/sim/messages/copilot","Negative G load !!!!!!!!!!!!!");
			#screen.log.write("Negative G load !!!", 1, 0, 0);
			blade_fail();
		}
		
	}
	
	
}

var	check_vne_structure = func{
	var kias = getprop("velocities/airspeed-kt");
	
	if(kias!=nil and kias>110){
		#setprop("/sim/sound/crash",1);
		#setprop("/sim/messages/copilot","VNE exceeded !!!!!!!!!!!!!");
		setprop("/sim/heli-realism-overspeed", 1);
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
		if(rpm!=nil and rpm>650){
			#setprop("/sim/sound/crash",1);
			#setprop("/sim/messages/copilot","Rotor overspeed !!!!!!!!!!!!!");
			#screen.log.write("Rotor overspeed !!!", 1, 0, 0);
			
			#uncomment when you want to crash
			#gyro_crashed = 1;
			blade_fail();
		}
		
	}
	
}

		
	
#if (getprop("/sim/heli-realism-fuelcons"))	
var blade_fail = func{
	
	if ( (gyro_crashed==0) )
	{
		gyro_crashed = 1;
		setprop("controls/engines/engine[0]/magnetos",0);
		setprop("/controls/rotor/brake", 1);
		
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
	
	#ground gear fix  old=15
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
		
		if (wght<0) {wght=0;}
		
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
	
	var descrate = getprop("velocities/vertical-speed-fps");
	descrate=descrate*60*(-1);
	
	var rotstall=getprop("/rotors/main/stall");
		
	#overspeed  kias>100 and kias>90
	if( rotstall!=nil and rotstall>0.1 and kias>70){
		#setprop("/sim/messages/copilot","VNE exceeded !!!!!!");
		#screen.log.write("VNE exceeded !!!", 1, 0, 0);
		
		#var wght2 =0;
		#if ( kias>90 ){
			setprop("/sim/heli-realism-overspeed", 1);
		#}
		
		#if (kias>160){
		#	wght2 = 50* rotstall;
		#	setprop("/sim/weight[6]/weight-lb",wght2);
		#}
		#else{
		#	setprop("/sim/weight[6]/weight-lb",0);
		#}
		
		#severe balde stall
		if ( getprop("/sim/heli-realism-airoverspeed"))
		{
			if ( rotstall>0.7){
				#screen.log.write("Blade Failure!!!", 1, 0, 0);
				blade_fail();
			}
		
		}
		
	}
	elsif ( (kias<18) and (descrate>300) and (mag>0) and (throttin<0.7) and
		!wow0 and !wow3 and !wow1 and !wow2)
	{
		setprop("/sim/heli-realism-overspeed", 1);
		#setprop("/sim/weight[6]/weight-lb",0);
	}
	else 
	{
		setprop("/sim/heli-realism-overspeed", 0);
		#setprop("/sim/weight[6]/weight-lb",0);
	}
	
	
	#var heliangle= getprop("/orientation/model/pitch-deg");
	#var heliangleside= getprop("/orientation/model/roll-deg");
	
	var heliangle= getprop("/orientation/pitch-deg");
	var heliangleside= getprop("/orientation/roll-deg");
	
	if ( getprop("sim/heli-realism-settling"))
	{	 
	#settling with power (VRS)
	if ( (heliangle>-20 and heliangle<20) 
		and  (heliangleside>-20 and heliangleside<20) 
		and (kias<15) and (descrate>350) and (mag>0) and
		!wow0 and !wow3 and !wow1 and !wow2)
	{
		var wght1 = 0;
		 
		#3 things for settling with power
		#desent grater than 300 fpm
		#airspeed under ETL 
		#producing lift - collective up over 20%-30%
		
		if (descrate>2350) {descrate=2350;} 
		
		throttin=1-throttin;
		if (throttin>0.3) {
		#old 10000
			wght1 = 5000 * (
			((descrate-350)/2000 )*0.3+ 
			((throttin-0.3)/0.8) *0.4+
			(kias/15)*0.3
			);
			
			#screen.log.write("Settling !!!", 1, 0, 0);
		}
		
		if (wght1<0) {wght1=0;}
		setprop("/sim/weight[5]/weight-lb",wght1);
		
	}
	else 
	{
		setprop("/sim/weight[5]/weight-lb",0);
	}
	}
	
}



#view 
var	look_up = func{
	
	if (getprop("sim/current-view/internal"))
	{
		var angle= getprop("sim/current-view/goal-pitch-offset-deg");
		if (angle==def_look_angle+30) {
			angle=angle-30;
			setprop("sim/current-view/goal-pitch-offset-deg", angle);
		} 
		else {
			angle=def_look_angle+30;
			setprop("sim/current-view/goal-pitch-offset-deg", angle);
		}
	}	
}


var	look_down = func{
	
	if (getprop("sim/current-view/internal"))
	{
		var angle= getprop("sim/current-view/goal-pitch-offset-deg");
		if (angle==def_look_angle-30) {
			angle=angle+30;
			setprop("sim/current-view/goal-pitch-offset-deg", angle);
			
		} 
		else {
			angle=def_look_angle-30;
			setprop("sim/current-view/goal-pitch-offset-deg", angle);
		}
	}	
	
}


#view.stepView(1)
#not used
var	stepView_new= func{
	
	screen.log.write("stepView_new", 1, 0, 0);
	
	if (getprop("sim/current-view/internal"))
	{
		
		var angle= getprop("sim/current-view/goal-pitch-offset-deg");
		if (angle==def_look_angle+30) {
			angle=angle-30;
			setprop("sim/current-view/goal-pitch-offset-deg", angle);
		} 
		elsif (angle==def_look_angle-30) {
			angle=angle+30;
			setprop("sim/current-view/goal-pitch-offset-deg", angle);
		} 
		
	}

	view.stepView(1);
}	


var	toggle_forward_trim= func{
	
	var x=getprop("/controls/flight/elevator-trim");
	if (x>0){ 
		setprop("/controls/flight/elevator-trim", 0);
		}
	else {	
		setprop("/controls/flight/elevator-trim", 0.27);
		}		
}	

#3 things for settling with power
#desent grater than 300 fpm
#producing lift collective up
#airspeed under ETL 


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


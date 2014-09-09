var low_fuel_warned=0;

var init = func {
	
	setprop("/consumables/fuel/tank[0]/level-gal_us",10); 
	setprop("/consumables/fuel/tank[1]/level-gal_us",0); 
	print("Init Nasal M-XE Fuel...done");
	main_loop();
}

setlistener("sim/signals/fdm-initialized", init);

var reinit = func {
	
	setprop("/consumables/fuel/tank[0]/level-gal_us",10); 
	setprop("/consumables/fuel/tank[1]/level-gal_us",0); 
	low_fuel_warned=0;
	print("ReInit Nasal M-XE Fuel...done");
	
}
setlistener("/sim/signals/reinit", reinit);

#main loop
var main_loop = func {

	setprop("/controls/rotors/engine-throttle",
		1-getprop("controls/engines/engine[0]/throttle") ); 
        
	check_fuel();	
	settimer(main_loop, 0.025);
}


#Fuel burn at cruise: 5 gph
#5 gph with 80% power

#(5*0.8)/3600 full powe per second
#0,00111 gal per sec
#1/10 sec = 0,0000111
#1/40 sec -25 hertz =0,0000111*4

# /consumables/fuel/tank/level-gal_us
# if mag on
# times throttle
# setprop("/sim/heli-realism-fuelcons", 0);
# set gear weights
# depending on 
# gear touchdown
# airspeed   getprop("velocities/airspeed-kt");
# throttle  /controls/engines/engine/throttle  /controls/engines/engine[0]/throttle
# magnets  /controls/engines/engine[0]/magnetos

#only main
var check_fuel1 = func{
	
	var throttin =  getprop("controls/engines/engine[0]/throttle"); 
	var mag = getprop("controls/engines/engine[0]/magnetos");
	var currfuel0 =  getprop("/consumables/fuel/tank[0]/level-gal_us");
		
	if (getprop("/sim/heli-realism-fuelcons"))
	{
		#out of fuel
		if ( (currfuel0<=0) ) 
		{
			setprop("controls/engines/engine[0]/magnetos",0);
		}
		elsif ( (mag>0) and (currfuel0>0) ) 
		{
			
			throttin=1-throttin;
			if (throttin<0.01){ throttin=0.01;}
			
			currfuel0 = currfuel0-(0.00002775*throttin);
			if (currfuel0<0) { currfuel0=0;}
			
			setprop("/consumables/fuel/tank[0]/level-gal_us",currfuel0);
			
		}
		
		
	}
	
}


#with aux
var check_fuel = func{
	
	var throttin =  getprop("controls/engines/engine[0]/throttle"); 
	var mag = getprop("controls/engines/engine[0]/magnetos");
	var currfuel0 =  getprop("/consumables/fuel/tank[0]/level-gal_us");
	var currfuel1 =  getprop("/consumables/fuel/tank[1]/level-gal_us");
	
	if (getprop("/sim/heli-realism-fuelcons"))
	{
		#out of fuel
		if (currfuel0==0) 
		{
			setprop("controls/engines/engine[0]/magnetos",0);
		}
		elsif ( (mag>0) and (currfuel0>0) ) 
		{
			
			if (low_fuel_warned==0 and currfuel0<1.0)
			{ 
				screen.log.write("Low Fuel Warning!!!", 1, 0, 0);
				low_fuel_warned=1;
			}
			else
			{
				if (currfuel0>=1.0)
				{
					low_fuel_warned=0;
				}
			}
			
			var tank_id=0;
			if ( currfuel1>0)
			{
				tank_id=1;
				currfuel0=currfuel1;
			}
			
			throttin=1-throttin;
			if (throttin<0.01){ throttin=0.01;}
			
			currfuel0 = currfuel0-(0.00002775*throttin);
			if (currfuel0<0) { currfuel0=0;}
			
			if (tank_id>0){
				setprop("/consumables/fuel/tank[1]/level-gal_us",currfuel0);
			}
			else {
				setprop("/consumables/fuel/tank[0]/level-gal_us",currfuel0);
			}
			

		}
		
	}
	
}

clc
clearvars
clear

%% Given Data
teeth_pinion = 24;
rpm = 5000;
power = 2.5; % in kW
reduction_ratio = 4;
pressure_angle = 20; % in degrees
helix_angle = 23; % in degrees
ultimate_strength_pinion = 750; % in MPa
ultimate_strength_gear = 750; % in MPa
service_factor = 1.5;
factor_of_safety = 2;
pitch_line_velocity = 10;
machining_grade = 4;

face_width = @(module) module * 10; % in mm
diameter = @(teeth, normal_module) (teeth * normal_module) / (cos(pi * helix_angle / 180));

%% part-1: find the normal module in the initial condition
normal_module_values = ...
    readtable("normal_module_helical_gear.csv").normal_module;
form_factor_values = readtable("form_factor.csv");
c_values = readtable("c_values.csv");
tolerance_values = readtable("tolerance.csv");

teeth_gear = reduction_ratio * teeth_pinion;
virtual_teeth = @(teeth) teeth / (cos(pi * helix_angle / 180) ^ 3);

form_factor_idx = find(form_factor_values.teeth >= virtual_teeth(teeth_pinion), 1);
form_factor = interp1( ...
    [form_factor_values.teeth(form_factor_idx - 1); form_factor_values.teeth(form_factor_idx)], ...
    [form_factor_values.form_factor(form_factor_idx - 1); form_factor_values.form_factor(form_factor_idx)], ...
    virtual_teeth(teeth_pinion));

rated_torque = (60 * (10 ^ 6) * power) / (2 * pi * rpm);

velocity_ratio = 5.6 / (5.6 + sqrt(pitch_line_velocity));
normal_module_initial = (factor_of_safety * ...
    (service_factor / velocity_ratio) * ...
    ((2 * rated_torque * cos(helix_angle * pi / 180)) / teeth_pinion) * ...
    (1 / (10 * ultimate_strength_pinion / 3 * form_factor))) ^ (1 / 3);

fprintf("The value of normal module from initial loading is: %.2f mm\n", normal_module_initial);

%% part-2: find the first preference of the normal module and main dimensions of the gear
normal_module = 1;
[normal_module_values_length, ~] = size(normal_module_values);
for i = 1 : normal_module_values_length
    if (normal_module_values(i, 1) - normal_module_initial > 0.1)
        normal_module = normal_module_values(i);
        break;
    end
end

diameter_pinion = diameter(teeth_pinion, normal_module);
diameter_gear = diameter(teeth_gear, normal_module);

fprintf("First preference of module is: %.2f mm\n", normal_module);
fprintf("Diameter of pinion is: %.2f mm\n", diameter_pinion);
fprintf("Diameter of gear is: %.2f mm\n", diameter_gear);

%% part-3: calculation of dynamic load and factor of safety

deformation_factor = 11400;
tolerance_factor = @(normal_module, diameter) normal_module + 0.25 * sqrt(diameter);
error = @(normal_module, diameter) ...
    tolerance_values(machining_grade, "constant").constant + ...
    tolerance_values(machining_grade, "coefficient").coefficient * tolerance_factor(normal_module, diameter);

tangential_force = 2 * rated_torque / diameter_pinion;

pitch_line_velocity_new = (pi * diameter_pinion * rpm) / (60 * (10 ^ 3));
total_error = (error(normal_module, diameter_pinion) + error(normal_module, diameter_gear)) / 1000;
x = 21 * pitch_line_velocity_new;
y = deformation_factor * ...
    total_error * ...
    face_width(normal_module) * ...
    ((cos(pi * helix_angle / 180)) ^ 2) + tangential_force;

dynamic_load = (x * y * cos(pi * helix_angle / 180)) / (x + sqrt(y));

effective_load = service_factor * tangential_force + dynamic_load;

beam_strength = normal_module * face_width(normal_module) * (ultimate_strength_pinion / 3) * form_factor;

correct_fos = beam_strength / effective_load;

fprintf("Dynamic Load: %.2f N\n", dynamic_load);
fprintf("Effective Load: %.2f N\n", effective_load);
fprintf("Correct Factor of Safety: %.2f\n", correct_fos);

%% part-4: calculation of surface hardness

wear_strength = effective_load * 2;
ratio_factor = (2 * teeth_gear) / (teeth_gear + teeth_pinion);
load_stress_factor = (wear_strength * ((cos(pi * helix_angle / 180)) ^ 2)) / (face_width(normal_module) * ratio_factor * diameter_pinion);
surface_hardness = 100 * sqrt(load_stress_factor / 0.16);

fprintf("Surface hardness of gears is: %.2f BHN\n", surface_hardness);
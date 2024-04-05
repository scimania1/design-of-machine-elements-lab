clc
clearvars
clear

%% Given Data

teeth_pinion = 24;
teeth_gear = 32;
rpm = 1440;
power = 12.5; % in kW
reduction_ratio = 4;
pressure_angle = 20; % in degrees
ultimate_strength_pinion = 750; % in MPa
ultimate_strength_gear = 750; % in MPa
service_factor = 1.5;
factor_of_safety = 2;
pitch_line_velocity = 7.5;
error_class = 3;

pitch_angle = atan(teeth_pinion / teeth_gear);

%% part-1: calculation of module on the basis of beam strength

form_factor_values = readtable("form_factor.csv");
c_values = readtable("c_values.csv");
max_error_values = readtable("max-error-bevel-gear.csv");

virtual_teeth = @(teeth) teeth / cos(pitch_angle);

form_factor_idx = find(form_factor_values.teeth >= virtual_teeth(teeth_pinion), 1);
form_factor = interp1( ...
    [form_factor_values.teeth(form_factor_idx - 1); form_factor_values.teeth(form_factor_idx)], ...
    [form_factor_values.form_factor(form_factor_idx - 1); form_factor_values.form_factor(form_factor_idx)], ...
    virtual_teeth(teeth_pinion));

rated_torque = (60 * (10 ^ 6) * power) / (2 * pi * rpm);

velocity_ratio = 5.6 / (5.6 + sqrt(pitch_line_velocity));
module_initial = (factor_of_safety * ...
    (service_factor / velocity_ratio) * ...
    ((2 * rated_torque) / teeth_pinion) * ...
    (1.5 / (10 * ultimate_strength_pinion / 3 * form_factor))) ^ (1 / 3);

fprintf("The value of module on the basis of beam strength is: %.2f mm\n", module_initial);

%% part-2: find the first preference of the normal module and main dimensions of the gear

module = ceil(module_initial);
if (module < 5)
    module = 5;
end

diameter_pinion = module * teeth_pinion;
diameter_gear = module * teeth_gear;
cone_diameter = sqrt((diameter_pinion / 2) ^ 2 + (diameter_gear / 2) ^ 2);

face_width = 10 * module;
if (cone_diameter / 3 < face_width)
    face_width = cone_diameter / 3;
end

fprintf("Module: %.2f mm\n", module);
fprintf("Diameter of pinion: %.2f mm\n", diameter_pinion);
fprintf("Diameter of gear: %.2f mm\n", diameter_gear);
fprintf("Cone Diameter: %.2f mm\n", cone_diameter);
fprintf("Face width: %.2f mm\n", face_width);

%% part-3: calculation of dynamic load and factor of safety

pitch_line_velocity_new = (pi * diameter_pinion * rpm) / (60 * (10 ^ 3));
deformation_factor = c_values(3, "Var2").Var2;
tangential_force = 2 * rated_torque / diameter_pinion;

max_error_idx = find(max_error_values.module == module);
error_class_str = sprintf("class%d", error_class);
max_error = max_error_values(max_error_idx, error_class_str).(error_class_str);

x = 21 * pitch_line_velocity_new;
y = deformation_factor * max_error * face_width + tangential_force;

dynamic_load = (x * y) / (x + sqrt(y));

effective_load = service_factor * tangential_force + dynamic_load;

beam_strength = module * face_width * (ultimate_strength_pinion / 3) * form_factor * (1 - face_width / cone_diameter);

correct_fos = beam_strength / effective_load;

fprintf("Dynamic Load: %.2f N\n", dynamic_load);
fprintf("Effective Load: %.2f N\n", effective_load);
fprintf("Correct Factor of Safety: %.2f\n", correct_fos);

%% part-4: calculation of surface hardness

wear_strength = 2 * effective_load;
ratio_factor = (2 * teeth_gear) / (teeth_gear + teeth_pinion * tan(pitch_angle));
load_stress_factor = (wear_strength * cos(pitch_angle)) / (0.75 * face_width * ratio_factor * diameter_pinion);
surface_hardness = 100 * sqrt(load_stress_factor / 0.16);

fprintf("Surface hardness of gears is: %.2f BHN\n", surface_hardness);
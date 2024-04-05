clc
clearvars
clear

pressure_angle = 20; % in degrees
teeth_pinion = 19;
teeth_gear = 40;
power = 7.5; % in kW
rpm = 1500;
service_factor = 1.5;
ultimate_strength_pinion = 600; % in MPa
ultimate_strength_gear = 600; % in MPa

teeth_weaker_part = teeth_pinion;
ultimate_strength_weaker_part = ultimate_strength_pinion;

face_width = @(module) module * 10; % in mm;

module_values = readtable("module.csv").module;
form_factor_values = readtable("form_factor.csv");
machining_grade_values = readtable("machining_grade.csv").grade;
c_values = readtable("c_values.csv");
tolerance_values = readtable("tolerance.csv");

prompt = "Are the gears made of the same material? (Y/n) ";
same_material_input = input(prompt, "s");
same_material = true;

if (isempty(same_material_input) || same_material_input == "y" || same_material_input == "Y")
    same_material = true;
else
    same_material = false;
end

get_form_factor = @(teeth) form_factor_values.form_factor(find(form_factor_values.teeth == teeth));

% find the weaker material
if (same_material == 0)
    prod_pinion = ultimate_strength_pinion * get_form_factor(teeth_pinion);
    prod_gear = ultimate_strength_gear * get_form_factor(teeth_gear);
    if (prod_pinion >= prod_gear)
        fprintf("Gear is the weaker component\n");
        teeth_weaker_part = teeth_gear;
        ultimate_strength_weaker_part = ultimate_strength_gear;
    else
        fprintf("Pinion is the weaker component\n");
    end
end

% part 1 - find the fos for initial loading
left = 1;
[right, ~] = size(module_values);
mid = floor(left + (right - left) / 2);
required_fos = 2;
net_effective_load = 0;
tangential_force = 0;
beam_strength = 0;
while (left <= right)
    module = module_values(mid);
    [tangential_force, beam_strength, net_effective_load, fos] = initial_fos( ...
        module, ...
        face_width(module), ...
        ultimate_strength_weaker_part, ...
        get_form_factor(teeth_weaker_part), ...
        service_factor, ...
        power, ...
        rpm, ...
        teeth_weaker_part);
    if (fos < 1.5)
        left = mid + 1;
    elseif (fos > 2)
        right = mid -1 ;
    else
        required_fos = fos;
        break;
    end
    mid = floor(left + (right - left) / 2);
end
required_module = module_values(mid);
fprintf("The suitable module for the gear is: %.2f mm\n", required_module);
fprintf("The value of initial factor of safety for module of %.2f mm is %f\n", required_module, required_fos);

% part 2 - find the suitable surface hardness
fos_pitting = 2;
wear_strength = net_effective_load * fos_pitting;
external_gears_input = input("Are the gears in external meshing? (Y/n) ", "s");
external_gears = true;
if (isempty(external_gears_input) || external_gears_input == "y" || external_gears_input == "Y")
    external_gears = true;
else
    external_gears = false;
end
ratio_factor = 0;
if (external_gears == true)
    ratio_factor = (2 * teeth_gear) / (teeth_gear + teeth_pinion);
else
    ratio_factor = (2 * teeth_gear) / (teeth_gear - teeth_pinion);
end
load_stress_factor = wear_strength / (face_width(required_module) * ratio_factor * required_module * teeth_weaker_part);
hardness = 100 * sqrt(load_stress_factor / 0.16);
fprintf("The surface hardness is %d BHN\n", ceil(hardness));

% part 3 - find fos for final loading condition
pitch_line_velocity = (pi * required_module * teeth_weaker_part * rpm) / (60 * (10 ^ 3));
deformation_factor = c_values(3, 2).Var2;
tolerance_factor = @(module, teeth) module + 0.25 * sqrt(module * teeth);

lo = 1;
[hi, ~] = size(tolerance_values);
mid = floor(lo + (hi - lo) / 2);
meshing_error = @(teeth, idx) ...
    tolerance_values.constant(idx) + tolerance_values.coefficient(idx) * tolerance_factor(required_module, teeth);
net_effective_load_final = 0;
net_effective_load_prev = 0;
while (lo < hi)
    meshing_error_pinion = meshing_error(teeth_pinion, mid);
    meshing_error_gear = meshing_error(teeth_gear, mid);
    total_error = (meshing_error_pinion + meshing_error_gear) / 1000;
    x = 21 * pitch_line_velocity;
    y = deformation_factor * total_error * face_width(required_module) + tangential_force;
    dynamic_load = (x * y) / (x + sqrt(y));
    p_eff = service_factor * tangential_force + dynamic_load;
    if (beam_strength < p_eff || wear_strength < p_eff)
        hi = mid - 1;
    else 
        net_effective_load_final = p_eff;
        lo = mid;
    end
    mid = floor(lo + (hi - lo) / 2);
end
final_fos = 1;
if (beam_strength < wear_strength)
    final_fos = beam_strength / net_effective_load_final;
else
    final_fos = wear_strength / net_effective_load_final;
end
fprintf("The final factor of safety is: %.2f\n", final_fos);
function [tangential_force, beam_strength, net_effective_load, fos] = initial_fos(module, face_width, ultimate_strength, form_factor, service_factor, power, rpm, teeth)
    torque = (60 * (10 ^ 6) * power) / (2 * pi * rpm);
    diameter = module * teeth;
    tangential_force = (2 * torque) / diameter;
    cv = velocity_factor(diameter, rpm);

    beam_strength = module * face_width * (ultimate_strength / 3) * form_factor;
    net_effective_load = (service_factor * tangential_force) / cv;

    fos = beam_strength / net_effective_load;
end

function cv = velocity_factor(diameter, rpm)
    pitch_line_velocity = (pi * diameter * rpm) / (60 * (10 ^ 3));
    if (pitch_line_velocity < 10)
        cv = 3 / (3 + pitch_line_velocity);
    elseif (pitch_line_velocity > 10 && pitch_line_velocity < 20)
        cv = 6 / (6 + pitch_line_velocity);
    else
        cv = 5.6 / (5.6 + sqrt(pitch_line_velocity));
    end
end

classdef H2StoreCycleEndpointTest < matlab.unittest.TestCase
    % H2STORECYCLEENDPOINTTEST Plot fields and times use selected state indices.
    methods (Test)

        function nonconsecutiveEndpoints(test)
            [model, states, schedule] = fixture();
            data = getH2CycleEndpointData(model, states, schedule);
            test.verifyEqual(data.steps, [2, 5, 7, 10]);
            test.verifyEqual(data.time, [3, 31, 127, 1023]);
            for k = 1:4
                step = data.steps(k);
                rs = [step; 2 * step];
                expected = 0.1 * rs ./ (1000 + 0.1 * rs);
                test.verifyEqual(data.massFraction{k}, expected, 'AbsTol', 1e-18);
            end
            firstSequential = 0.1 * [1; 2] ./ (1000 + 0.1 * [1; 2]);
            test.verifyNotEqual(data.massFraction{1}, firstSequential);
        end

        function stageMetadata(test)
            [model, states, schedule] = fixture();
            for k = 1:numel(schedule.control)
                schedule.control(k).W.stage = schedule.control(k).W.name;
                schedule.control(k).W.name = 'Storage';
            end
            data = getH2CycleEndpointData(model, states, schedule);
            test.verifyEqual(data.steps, [2, 5, 7, 10]);
            test.verifyEqual(data.time, [3, 31, 127, 1023]);
        end

        function zeroDissolvedHydrogen(test)
            [model, states, schedule] = fixture();
            states{2}.rs(:) = 0;
            data = getH2CycleEndpointData(model, states, schedule);
            test.verifyEqual(data.massFraction{1}, zeros(2, 1));
        end

        function emptySchedule(test)
            [model, ~, schedule] = fixture();
            schedule.step.control = zeros(0, 1);
            schedule.step.val = zeros(0, 1);
            data = getH2CycleEndpointData(model, {}, schedule);
            test.verifyEmpty(data.steps);
            test.verifySize(data.time, [1, 0]);
            test.verifySize(data.massFraction, [1, 0]);
        end

    end
end

function [model, states, schedule] = fixture()
    model.fluid = struct('rhoOS', 1000, 'rhoGS', 0.1);
    names = {'cushion', 'charge', 'shut', 'discharge'};
    for k = 1:numel(names)
        schedule.control(k).W.name = names{k};
    end
    schedule.step.control = [1; 1; 2; 2; 2; 3; 3; 4; 4; 4];
    schedule.step.val = 2.^(0:9)';
    states = cell(10, 1);
    for k = 1:10
        states{k} = struct('rs', [k; 2 * k]);
    end
end

%{
Copyright 2009-2026 SINTEF Digital, Mathematics & Cybernetics.

This file is part of h2sim.

h2sim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

h2sim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with h2sim.  If not, see <http://www.gnu.org/licenses/>.
%}

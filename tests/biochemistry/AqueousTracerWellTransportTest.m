classdef AqueousTracerWellTransportTest < matlab.unittest.TestCase
    % Reaction-free tracer transport must retain aqueous well outflow.
    % These small equation/source checks require MRST, but no PHREEQC engine.

    methods (Test)

        function producerRemovesTracersFromReactionFreeBalances(test)
            [model, state0, state, problem, dt] = producerFixture();
            [names, wellSources] = aqueousWellSources(model, state);
            mass = model.getProp(state, 'AqueousTracerMass');
            mass0 = model.getProp(state0, 'AqueousTracerMass');
            for i = 1:numel(names)
                equation = strcmpi(problem.equationNames, names{i});
                test.assertEqual(nnz(equation), 1);
                % Internal face fluxes cancel in the domain-wide balance.
                % A producer must remove the local aqueous concentration.
                accumulation = sum(value(mass{i}) - value(mass0{i})) ./ dt;
                expected = accumulation - sum(wellSources{i});
                test.verifyGreaterThan(-sum(wellSources{i}), 0, names{i});
                test.verifyEqual(sum(value(problem.equations{equation})), ...
                    expected, 'AbsTol', 1e-10, 'RelTol', 1e-10, names{i});
            end
        end

        function disabledSourcesExcludeSRBButRetainWellOutflow(test)
            [model, state0, state, ~, dt] = producerFixture();
            [names, wellSources] = aqueousWellSources(model, state);
            fd = model.FlowDiscretization;
            facility = model.FacilityModel;
            inactive = facility.getAqueousTracerSources(fd, state, state0, dt);
            for i = 1:numel(names)
                test.verifyEqual(value(inactive{i}), wellSources{i}, ...
                    'AbsTol', 1e-12, 'RelTol', 1e-12, names{i});
            end

            % Excite the real SRB source with anhydrite dissolution to show
            % that the disabled-stage check is not passing on zero kinetics.
            activeModel = model;
            activeModel.reactionsEnabled = true;
            facility.ReservoirModel = activeModel;
            active = facility.getAqueousTracerSources(fd, state, state0, dt);
            sulfate = strcmpi(names, 'SO4');
            test.verifyGreaterThan(norm(value(active{sulfate}) - ...
                value(inactive{sulfate}), inf), 1e-12);
        end

    end
end

function [model, state0, state, problem, dt] = producerFixture()
    [~, model, schedule, state0] = setupH2StorageExampleWithSRB_benchmark( ...
        'gridCells', 3, 'domainLength', 5, 'scheduleMode', 'injection', ...
        'carbonateBuffer', true, 'initialHCO3', 1.370e-3, ...
        'initialOverallCO2', 0, 'paperBiomassKinetics', true, 'nbact0', 1, ...
        'phreeqcTimestepCoupling', false);
    model.reactionsEnabled = false;
    model.enableSulfateSource = true;
    state0.tracerHS = repmat(0.2, model.G.cells.num, 1);
    well = schedule.control(1).W;
    well.type = 'bhp';
    well.val = state0.pressure(well.cells(1)) - barsa();
    well.sign = -1;
    well.name = 'Producer';
    well.compi = [1, 0];
    schedule.control(1).W = well;
    forces = schedule.control(1);
    model = model.validateModel(forces);
    schedule = model.validateSchedule(schedule);
    forces = schedule.control(1);
    state0 = model.validateState(state0);
    [model, state0] = model.updateForChangedControls(state0, forces);
    dt = 0.1 * day;
    [model, state] = model.prepareTimestep(state0, state0, dt, forces);
    % The benchmark disables dissolution on its registered state functions.
    % Re-enable both source computers, not only the model-level option.
    rate = model.FlowDiscretization.getStateFunction('SRBTracerConvRate');
    rate.enable_sulfate_source = true;
    model.FlowDiscretization = model.FlowDiscretization.setStateFunction( ...
        'SRBTracerConvRate', rate);
    rate = model.FacilityModel.FacilityFlowDiscretization.getStateFunction( ...
        'SRBTracerConvRate');
    rate.enable_sulfate_source = true;
    model.FacilityModel.FacilityFlowDiscretization = ...
        model.FacilityModel.FacilityFlowDiscretization.setStateFunction( ...
        'SRBTracerConvRate', rate);
    [problem, state] = model.getEquations(state0, state, dt, forces);
end

function [names, sources] = aqueousWellSources(model, state)
    facility = model.FacilityModel;
    map = facility.getProp(state, 'FacilityWellMapping');
    flux = facility.getProp(state, 'PhaseFlux');
    liquidFlux = value(flux{model.getLiquidIndex()});
    assert(any(liquidFlux < 0), 'Fixture must exercise liquid well outflow.');
    names = model.getAqueousTracerNames();
    sources = cell(size(names));
    for i = 1:numel(names)
        concentration = value(model.getProp(state, lower(names{i})));
        rate = min(liquidFlux, 0) .* concentration(map.cells);
        sources{i} = accumarray(map.cells, rate, [model.G.cells.num, 1]);
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

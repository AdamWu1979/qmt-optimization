classdef (Abstract = true) SeqJacobian < handle
    %SEQJacobian Abstract class to calculate and store Jacobian for an MRI
    %pulse sequence
    %

    properties (Access = protected)
        protocolObj
        tissueParamsObj
        jacobianStruct = struct('jacobianMatrix',[]);
        derivMapDirection = 'forward';
        deltaPerc = 10^(-2); % Percentage difference for derivatives calculations
    end

    methods (Access = public)
        % Constructor
        % Must be explicitely called in all subclass constructors prior to
        % handling the object.
        % e.g. obj = obj@SeqJacobian(SeqProtocolInstance, TissueParamsInstance);
        
        function obj = SeqJacobian(SeqProtocolInstance, TissueParamsInstance)
            assert(isa(SeqProtocolInstance, 'SeqProtocol'), 'SeqJacobian:missingClass', 'First input argument to SeqJacobian subclasses must be an object that has a parent class of type ''SeqProtocol''')
            assert(isa(TissueParamsInstance, 'TissueParams'), 'TissueParams:missingClass', 'Second input argument to SeqJacobian subclasses must be an object that has a parent class of type ''TissueParams''')
        end
        
        % Get methods
        jacobianMatrix = getJacobian(obj)
        jacobianStruct = getJacobianStruct(obj)

        % Methods for Jacobian computation
        computeOpts = compute(obj, computeOpts)
    end

    methods (Access = protected)
        % Get methods
        remainingRows = getRemainingRows(obj)
            % **Abstract**
            protPoint = getProtocolPoint(obj, rowIndex)

        % Generate methods
        tissueJacStruct = genParamsJacStruct(obj)
            % **Abstract**
            deltaProtPoint = genDeltaProtPoint(obj, protPoint, paramIndex)
            deltaTissueParams = genDeltaTissueParams(obj, tissueJacStruct, tissueParams, computeOpts, paramIndex) % Abstract
        
            % Methods for Jacobian computation
        derivValues = calcDerivative(obj, func_x, func_x_delta, delta);
            % **Abstract**
            signalValues = simulateSignal(obj, curProtPoint, tissueParams) 
    end

    methods (Static, Access = public)
        % Mapping methods
        signVal = derivMap(mapType);
    end

end


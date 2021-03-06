classdef (TestTags = {'SPGR', 'Unit'}) SPGR_Jacobian_Test < matlab.unittest.TestCase

    properties
        demoProtocol = 'savedprotocols/demo_SPGR_Protocol_for_UnitTest.mat';
        demoTissue = [0.122 3.97 1.1111 1 0.0272 1.0960e-05];
        
        expected_genParamsJacStruct_Fields={'keys','value','differential'}
        
        p = []; % parpool instance
    end
    
    methods (TestClassSetup)
        function initParPool(testCase)
           delete(gcp('nocreate'))
           testCase.p = parpool(feature('numCores'));
        end
    end
    
    methods (TestClassTeardown)
        function delParPool(testCase)
            delete(testCase.p)
        end
    end
    
    methods (Test)
         function test_SPGR_Jacbobian_throws_error_for_bad_arg_parent_types(testCase)
                          
             % Bad first argument parent type
             testError.identifier='No Error';
             try 
                 SPGR_Jacobian('wrongType', SPGR_Tissue(testCase.demoTissue))
             catch ME
                 testError = ME;
             end
             
             assertEqual(testCase, testError.identifier, 'SeqJacobian:missingClass');

             % Bad second argument parent type
             clear testError
             testError.identifier='No Error';
             try 
                 SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), 'wrongType')
             catch ME
                 testError = ME;
             end

             assertEqual(testCase, testError.identifier, 'TissueParams:missingClass');

         end

         
         
        % Static Methods
        function test_SPGR_Tissue_method_derivMap_returns_expected_values(testCase)
            
            assertEqual(testCase, SPGR_Jacobian.derivMap('forward'), 1);
            assertEqual(testCase, SPGR_Jacobian.derivMap('backward'), -1);

        end
        
        function test_SPGR_Tissue_method_derivMap_throws_error_for_bad_case(testCase)

            testError.identifier='No Error';
            try 
                SPGR_Jacobian.derivMap('Non-existing case')
            catch ME
                testError = ME;
            end

            assertEqual(testCase, testError.identifier, 'derivMap:incorrectArg');

        end
        
        % Get methods
        function test_getJacobian_returns_a_type_double_variable(testCase)
            testObject = SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue));
            assertInstanceOf(testCase, testObject.getJacobian, 'double');
        end
    
        % Methods for Jacobian computation
        function test_compute_returns_error_for_unkown_computOpts_mode(testCase)
            testObject = SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue));
            computeOpts.mode = 'UnKn0wnM0dE';
            
            % Preload testError for test
            testError.identifier='No Error';
            try 
                testObject.compute(computeOpts);
            catch ME
                testError = ME;
            end
            
            assertEqual(testCase, testError.identifier, 'SPGR_Jacobian:unknownComputeMode');
        end

        function test_compute_throws_warning_when_computeOpts_mode_is_Completed(testCase)
            testObject = SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue));
            computeOpts.mode = 'Completed';
            
            % Reset the last warning to a new string
            warning('Temporary warning for unit test of SPGR_Jacobian.compute')

            testObject.compute(computeOpts);

            assertEqual(testCase, lastwarn, 'computeOpts.mode flag was set to Completed, obj.compute returned without further computation of Jacobian.');
        end


        function test_compute_compOpts_and_jacStruct_unchanged_for_Completed(testCase)
            testObject = SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue));
            computeOpts.mode = 'Completed';
            
            prev_computeOpts = computeOpts;
            prev_jacobianMat = testObject.getJacobian();
            
            computeOpts = testObject.compute(computeOpts);

            assertEqual(testCase,              computeOpts, prev_computeOpts);            
            assertEqual(testCase, testObject.getJacobian(), prev_jacobianMat);

        end

        function test_compute_New_returns_Resume_or_Completed(testCase)
            testObject = SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue));
 
            computeOpts.mode = 'New';
            computeOpts.paramsOfInterest = {'F', 'kf', 'T2r', 'T2f', 'B1_IR'};
            computeOpts.lineBuffer = 2;

            computeOpts = testObject.compute(computeOpts);

            assertTrue(testCase, any(ismember({'Resume', 'Complete'}, computeOpts.mode)));            
        end

        function test_compute_Resume_returns_Resume_or_Completed(testCase)
            testObject = SPGR_Jacobian(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue));
 
            computeOpts.mode = 'Resume';
            computeOpts.paramsOfInterest = {'F', 'kf', 'T2r', 'T2f', 'B1_IR'};
            computeOpts.lineBuffer = 2;

            computeOpts = testObject.compute(computeOpts);

            assertTrue(testCase, any(ismember({'Resume', 'Complete'}, computeOpts.mode)));            
        end

        function test_compute_New_sets_up_a_jacobian_template_with_proper_dims(testCase)
           protocolObj = SPGR_Protocol(testCase.demoProtocol);
            
           testObject = SPGR_Jacobian(protocolObj, SPGR_Tissue(testCase.demoTissue));

           computeOpts.mode = 'New';
           computeOpts.paramsOfInterest = {'F', 'kf', 'T2r', 'T2f', 'B1_IR', 'B1_VFA'};
           computeOpts.lineBuffer = 2;

           computeOpts = testObject.compute(computeOpts);

           expectedJacobianSize = [protocolObj.getNumberOfMeas length(computeOpts.paramsOfInterest)];
           assertEqual(testCase, size(testObject.getJacobian), expectedJacobianSize);            
        end
       
        function test_compute_lineBuffer_larger_than_rem_array_doesnt_error(testCase)
           protocolObj = SPGR_Protocol(testCase.demoProtocol);
            
           testObject = SPGR_Jacobian(protocolObj, SPGR_Tissue(testCase.demoTissue));

           computeOpts.mode = 'New';
           computeOpts.paramsOfInterest = {'kf'};
           computeOpts.lineBuffer = protocolObj.getNumberOfMeas + 1;

           testObject.compute(computeOpts);

           assertEqual(testCase, size(testObject.getJacobian, 1), protocolObj.getNumberOfMeas);
       end
        
    end

end

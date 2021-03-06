classdef (TestTags = {'SPGR', 'Integration'}) SPGR_MonteCarlo_Test < matlab.unittest.TestCase

    properties
        demoProtocol = 'savedprotocols/demo_SPGR_Protocol_for_UnitTest.mat';
        demoTissue = [0.122 3.97 1.1111 1 0.0272 1.0960e-05];
        demoFitOpts = 'savedfitopts/demo_SPGR_FitOpts_for_UnitTest.mat';
    end
    
    methods (TestClassSetup)

    end
    
    methods (TestClassTeardown)

    end
    
    methods (Test)
         %% Initialization Tests
         %
         
         function test_SPGR_MonteCarlo_throws_error_for_bad_arg_parent_types(testCase)
                          
             % Bad first argument parent type
             testError.identifier='No Error';
             try 
                 SPGR_MonteCarlo('wrongType', SPGR_Tissue(testCase.demoTissue), SPGR_FitOpts(testCase.demoFitOpts))
             catch ME
                 testError = ME;
             end
             
             assertEqual(testCase, testError.identifier, 'SeqJacobian:missingClass');

             % Bad second argument parent type
             clear testError
             testError.identifier='No Error';
             try 
                 SPGR_MonteCarlo(SPGR_Protocol(testCase.demoProtocol), 'wrongType', SPGR_FitOpts(testCase.demoFitOpts))
             catch ME
                 testError = ME;
             end

             assertEqual(testCase, testError.identifier, 'TissueParams:missingClass');

             % Bad third argument parent type
             clear testError
             testError.identifier='No Error';
             try 
                 SPGR_MonteCarlo(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue), 'wrongType')
             catch ME
                 testError = ME;
             end

             assertEqual(testCase, testError.identifier, 'SeqFitOpts:missingClass');
             
         end

         function test_SPGR_MonteCarlo_doesnt_throw_error_during_proper_initiali(testCase)
             testError.identifier='No Error';
             
             try 
                 SPGR_MonteCarlo(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue), SPGR_FitOpts(testCase.demoFitOpts));
             catch ME
                 testError = ME;
             end
            
             assertEqual(testCase, testError.identifier, 'No Error');
         end

         function test_SPGR_MonteCarlo_deep_copy_returns_different_handle(testCase)
             
             originalObj = SPGR_MonteCarlo(SPGR_Protocol(testCase.demoProtocol), SPGR_Tissue(testCase.demoTissue), SPGR_FitOpts(testCase.demoFitOpts));
             
             newObj = originalObj.copy();
             
             testCase.assertTrue(ne(newObj, originalObj));
         end

         %% Get Methods Test
         %
         
         function test_SPGR_MonteCarlo_getNoiselessSignal_returns_expected_dims(testCase)
             protocolObj = SPGR_Protocol(testCase.demoProtocol);
             tissueObj = SPGR_Tissue(testCase.demoTissue);
             fitOptsObj = SPGR_FitOpts(testCase.demoFitOpts);
             
             MCobj = SPGR_MonteCarlo(protocolObj, tissueObj, fitOptsObj);
             
             prot = protocolObj.getProtocol();
             
             if size(prot.Angles) == size(prot.Offsets)
                numMeas = size(prot.Angles);
             else
                 error('Unexpected protocol structure format; size of Angles and Offsets not equal.')
             end
                          
             assertEqual(testCase, numMeas, size(MCobj.getNoiselessSignal()));
         end
         
         %% Generate Tests
         %

         function test_SPGR_MonteCarlo_genNoisyDataset_returns_expected_dims(testCase)
             protocolObj = SPGR_Protocol(testCase.demoProtocol);
             tissueObj = SPGR_Tissue(testCase.demoTissue);
             fitOptsObj = SPGR_FitOpts(testCase.demoFitOpts);
             
             MCobj = SPGR_MonteCarlo(protocolObj, tissueObj, fitOptsObj);
             
             snrVal = 150;
             numPoints = 10000;
             noisyDataSet = MCobj.genNoisyDataset(snrVal, numPoints);
             
             assertEqual(testCase, [size(MCobj.getNoiselessSignal(), 1), numPoints], size(noisyDataSet))
         end
         
         %% Data preparation tests
         %
         
         function test_SPGR_MonteCarlo_prep_returns_expected_noiseless_sizes(testCase)
             protocolObj = SPGR_Protocol(testCase.demoProtocol);
             tissueObj = SPGR_Tissue(testCase.demoTissue);
             fitOptsObj = SPGR_FitOpts(testCase.demoFitOpts);
             
             MCobj = SPGR_MonteCarlo(protocolObj, tissueObj, fitOptsObj);
             
             snrVal = 150;
             numPoints = 10000;
             MCobj.genNoisyDataset(snrVal, numPoints);
             
             data = MCobj.prep();
             
             dataStruct = data.noiselessFittingData;
             
             assertEqual(testCase, size(dataStruct.MTdata), [1 1 1 10])
             assertEqual(testCase, size(dataStruct.B0map) , [1 1])
             assertEqual(testCase, size(dataStruct.B1map) , [1 1])
             assertEqual(testCase, size(dataStruct.R1map) , [1 1])
             assertEqual(testCase, size(dataStruct.Mask)  , [1 1])
         end
         
         function test_SPGR_MonteCarlo_prep_returns_expected_noisy_sizes(testCase)
             protocolObj = SPGR_Protocol(testCase.demoProtocol);
             tissueObj = SPGR_Tissue(testCase.demoTissue);
             fitOptsObj = SPGR_FitOpts(testCase.demoFitOpts);
             
             MCobj = SPGR_MonteCarlo(protocolObj, tissueObj, fitOptsObj);           
             
             snrVal = 150;
             numPoints = 10000;
             MCobj.genNoisyDataset(snrVal, numPoints);
             
             data = MCobj.prep();
             
             dataStruct = data.noisyFittingData;
             
             assertEqual(testCase, size(dataStruct.MTdata), [numPoints 1 1 10])
             assertEqual(testCase, size(dataStruct.B0map) , [numPoints 1])
             assertEqual(testCase, size(dataStruct.B1map) , [numPoints 1])
             assertEqual(testCase, size(dataStruct.R1map) , [numPoints 1])
             assertEqual(testCase, size(dataStruct.Mask)  , [numPoints 1])
         end
         
         function test_SPGR_MonteCarlo_prep_errorStruct_returns_expected_vals(testCase)
             protocolObj = SPGR_Protocol(testCase.demoProtocol);
             tissueObj = SPGR_Tissue(testCase.demoTissue);
             fitOptsObj = SPGR_FitOpts(testCase.demoFitOpts);
             
             MCobj = SPGR_MonteCarlo(protocolObj, tissueObj, fitOptsObj);
             
             snrVal = 150;
             numPoints = 10000;
             MCobj.genNoisyDataset(snrVal, numPoints);
             
             %% B1
             %
             prepErrorStruct.name = 'B1'; 
             prepErrorStruct.errorPerc = 5;
             
             data = MCobj.prep(prepErrorStruct);
             
             dataStruct = data.noiselessFittingData;
             
             actualValue = dataStruct.B1map;
             expectedValue = protocolObj.ancillaryMeasurements.idealVals('B1map')*(1+prepErrorStruct.errorPerc/100);
             
             assertEqual(testCase, actualValue, expectedValue)
             
             %% T1
             %
             
             prepErrorStruct.name = 'T1'; 
             prepErrorStruct.errorPerc = 10;
             
             data = MCobj.prep(prepErrorStruct);
             
             dataStruct = data.noiselessFittingData;
             
             actualValue = dataStruct.R1map;
             
             idealT1 = 1/protocolObj.ancillaryMeasurements.idealVals('R1map');
             
             expectedValue = 1/(idealT1*(1+prepErrorStruct.errorPerc/100));
             
             assertEqual(testCase, actualValue, expectedValue)
             
             %% B1_VFA
             %
             
             prepErrorStruct.name = 'B1_VFA'; 
             prepErrorStruct.errorPerc = 25;
             
             data = MCobj.prep(prepErrorStruct);
             
             dataStruct = data.noiselessFittingData;
             
             % B1 map assert
             actualValue = dataStruct.B1map;
             expectedValue = protocolObj.ancillaryMeasurements.idealVals('B1map')*(1+prepErrorStruct.errorPerc/100);
             assertEqual(testCase, actualValue, expectedValue)
             
             % R1 map assert
             actualValue = dataStruct.R1map;

             TR = 0.025; % s
             FAs = [3 20]; % deg
             trueT1 = 1/protocolObj.ancillaryMeasurements.idealVals('R1map');
             B1val = protocolObj.ancillaryMeasurements.idealVals('B1map')*(1 + prepErrorStruct.errorPerc/100);
             [errT1Val , ~, ~, ~] = estimateVFAT1Error(trueT1, TR, FAs, B1val);
             
             expectedValue = (1/errT1Val); % R1 = 1/T1;
             
             assertEqual(testCase, actualValue, expectedValue)

         end
         
         %% Fit test
         %
         
         function test_SPGR_MonteCarlo_fit_returns_expected_sizes(testCase)
             protocolObj = SPGR_Protocol(testCase.demoProtocol);
             tissueObj = SPGR_Tissue(testCase.demoTissue);
             fitOptsObj = SPGR_FitOpts(testCase.demoFitOpts);
             
             MCobj = SPGR_MonteCarlo(protocolObj, tissueObj, fitOptsObj);
             
             snrVal = 150;
             numPoints = 10;
             MCobj.genNoisyDataset(snrVal, numPoints);
             
             data = MCobj.prep();
             MCobj.fit();      
             
             fitResults = MCobj.getFitResults();
             
             assertEqual(testCase, size(fieldnames(fitResults)), [2 1])
             assertEqual(testCase, size(fitResults.noiselessDataset), size(fitResults.noisyDataset))
             assertEqual(testCase, size(fitResults.noiselessDataset.F), [1 1])
             assertEqual(testCase, size(fitResults.noisyDataset.F), [numPoints 1])
             assertEqual(testCase, fitResults.noisyDataset.fields, {'F';'kf';'kr';'R1f';'R1r';'T2f';'T2r';'resnorm'})
         end
    end

end

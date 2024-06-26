close all; clear; %clear classes;
clc; 

RedoLinearization = false; %not needed, we use finite-difference

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dynamics

LinkArray = SRD_get('LinkArray');

SymbolicEngine = SRDSymbolicEngine('LinkArray', LinkArray, 'Casadi', false);
SymbolicEngine.InitializeLinkArray();

SRD_dynamics_derive_JacobiansForLinkArray('SymbolicEngine', SymbolicEngine);

H = SRD_dynamics_derive_JSIM('SymbolicEngine', SymbolicEngine);

[in, dH] = SRD_dynamics_derive_GeneralizedInertialForces_via_dH(...
    'SymbolicEngine', SymbolicEngine, ...
    'JointSpaceInertiaMatrix', H);

g = SRD_dynamics_derive_GeneralizedGravitationalForces(...
    'SymbolicEngine', SymbolicEngine, ...
    'GravitationalConstant', [0; 0; -9.8]);

d = SRD_dynamics_derive_GeneralizedDissipativeForces_uniform(...
    'SymbolicEngine', SymbolicEngine, ...
    'UniformCoefficient', 1);

%NaiveControlMap
% T = SRD_dynamics_derive_ControlMap_eye(...
%     'SymbolicEngine', SymbolicEngine);
T=sym([1;0;0]);        
c = (in + g + d);

description = SRD_generate_dynamics_generalized_coordinates_model(...
    'SymbolicEngine', SymbolicEngine, ...
    'H', H, ...
    'c', c, ...
    'T', T, ...
    'Symbolic_ToOptimizeFunctions', true, ...
    'Casadi_cfile_name', 'g_dynamics_generalized_coordinates', ...
    'FunctionName_H', 'g_dynamics_H', ...
    'FunctionName_c', 'g_dynamics_c', ...
    'FunctionName_T', 'g_dynamics_T', ...
    'Path', 'Dynamics/');

Handler_dynamics_generalized_coordinates_model = SRD_get_handler__dynamics_generalized_coordinates_model('description', description);
SRD_save(Handler_dynamics_generalized_coordinates_model, 'Handler_dynamics_generalized_coordinates_model');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constraints

%%%%%%%%%%%%
%construct constraint
constraint = SymbolicEngine.LinkArray(4).AbsoluteFollower(2:3);          
 

[description, F, dF] = SRD_generate_second_derivative_Jacobians('SymbolicEngine', SymbolicEngine, ...
    'Task',                                   constraint, ...
    'Casadi_cfile_name',                     'g_Constraints', ...
    'Symbolic_ToSimplify',                    true, ...
    'Symbolic_UseParallelizedSimplification', false, ...
    'Symbolic_ToOptimizeFunctions',           true, ...
    'FunctionName_Task',                     'g_Constraint', ...
    'FunctionName_TaskJacobian',             'g_Constraint_Jacobian', ...
    'FunctionName_TaskJacobian_derivative',  'g_Constraint_Jacobian_derivative', ...
    'Path',                                  'Constraints/');


Handler_Constraints_Model = SRD_get_handler__Constraints_model('description', description, ...
    'dof_configuration_space_robot', SymbolicEngine.dof);
SRD_save(Handler_Constraints_Model, 'Handler_Constraints_Model');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% External input

%%%%%%%%%%%%
%construct constraint
external_force_application = SymbolicEngine.LinkArray(3).AbsoluteCoM(3);       
 

[description, S, dS] = SRD_generate_second_derivative_Jacobians('SymbolicEngine', SymbolicEngine, ...
    'Task',                                   external_force_application, ...
    'Casadi_cfile_name',                     'g_Constraints', ...
    'Symbolic_ToSimplify',                    true, ...
    'Symbolic_UseParallelizedSimplification', false, ...
    'Symbolic_ToOptimizeFunctions',           true, ...
    'FunctionName_Task',                     'g_ExtenalForce', ...
    'FunctionName_TaskJacobian',             'g_ExtenalForce_Jacobian', ...
    'FunctionName_TaskJacobian_derivative',  'g_ExtenalForce_Jacobian_derivative', ...
    'Path',                                  'ExtenalForce/');


Handler_ExtenalForce_Model = SRD_get_handler__Constraints_model('description', description, ...
    'dof_configuration_space_robot', SymbolicEngine.dof);
SRD_save(Handler_ExtenalForce_Model, 'Handler_ExtenalForce_Model');







    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



if RedoLinearization
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Linearization 
    
    [description, A, B, iH] = SRD_generate_dynamics_linearization(...
        'SymbolicEngine',                         SymbolicEngine, ...
        'H', H, ...
        'c', c, ...
        'T', T, ...
        'Symbolic_ToOptimizeFunctions',           true, ...
        'Casadi_cfile_name',                      'g_dynamics_linearization', ...
        'FunctionName_A',                         'g_linearization_A', ...
        'FunctionName_B',                         'g_linearization_B', ...
        'Path',                                   'Linearization/');
    
    Handler_dynamics_Linearized_Model = SRD_get_handler__dynamics_linearized_model('description', description);
    SRD_save(Handler_dynamics_Linearized_Model, 'Handler_dynamics_Linearized_Model');
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Linearization c
%     
%     [description, Ac, Bc, iM] = SRD_generate_dynamics_linearization_c(...
%         'SymbolicEngine',                         SymbolicEngine, ...
%         'H', H, ...
%         'c', c, ...
%         'T', T, ...
%         'F', F, ...
%         'dF', dF, ...
%         'Symbolic_ToOptimizeFunctions',           true, ...
%         'Casadi_cfile_name',                      'g_dynamics_linearization', ...
%         'FunctionName_A',                         'g_linearization_A', ...
%         'FunctionName_B',                         'g_linearization_B', ...
%         'Path',                                   'Linearization_c/');
%     
%     Handler_dynamics_Linearized_Model = SRD_get_handler__dynamics_linearized_model('description', description);
%     SRD_save(Handler_dynamics_Linearized_Model, 'Handler_dynamics_Linearized_Model_c');
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inverse kinematics

%%%%%%%%%%%%
%construct inverse kinematics task
% rC = SymbolicEngine.GetCoM;
Task = [SymbolicEngine.q(1); constraint]; 
%%%%%%%%%

description = SRD_generate_second_derivative_Jacobians('SymbolicEngine', SymbolicEngine, ...
    'Task',                                      Task, ...
    'Casadi_cfile_name',                         'g_InverseKinematics', ...
    'Symbolic_ToSimplify',                       true, ...
    'Symbolic_UseParallelizedSimplification',    false, ...
    'Symbolic_ToOptimizeFunctions',              true, ...
    'FunctionName_Task',                         'g_InverseKinematics_Task', ...
    'FunctionName_TaskJacobian',                 'g_InverseKinematics_TaskJacobian', ...
    'FunctionName_TaskJacobian_derivative',      'g_InverseKinematics_TaskJacobian_derivative', ...
    'Path',                                      'InverseKinematics/');

Handler_IK_Model = SRD_get_handler__IK_model('description', description, ...
    'dof_configuration_space_robot', SymbolicEngine.dof);
SRD_save(Handler_IK_Model, 'Handler_IK_Model');




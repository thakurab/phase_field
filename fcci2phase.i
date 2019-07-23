[Mesh]
  type = GeneratedMesh
  dim = 2
  elem_type = QUAD4
  nx = 200
  ny = 1
  nz = 0
  xmin = -10
  xmax = 10
  ymin = 0
  ymax = 1
  zmin = 0
  zmax = 0
[]

# Defining an AuxVariables for free energy calculation
[AuxVariables]
  [./Fglobal]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

# Defining different parameters
[Variables]
  [./eta]
    order = FIRST
    family = LAGRANGE
  [../]

  [./c]
    order = FIRST
    family = LAGRANGE
  [../]

  [./w]
    order = FIRST
    family = LAGRANGE
  [../]

  [./cl]
    order = FIRST
    family = LAGRANGE
  [../]

  [./cs]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[ICs]
  [./eta]
    variable = eta
    type = FunctionIC
    #type = RandomIC
    #min = 0.4
    #max = 0.6
    function = ic_func_eta
  [../]
  [./c]
    variable = c
    type = FunctionIC
    #type = RandomIC
    #min = 0.4
    #max = 0.6
    function = ic_func_c
  [../]
[]

# Defining the equilibrium phase field profile as described in the KKS model.
[Functions]
  [./ic_func_eta]
    type = ParsedFunction
    #value = x/20
    value = (tanh(x)+1)/2
  [../]

  [./ic_func_c]
    type = ParsedFunction
    #value = x/20
    value = (tanh(x*5)+1)/2
    #value = 0.9*(0.5*(1.0-tanh(x/sqrt(2.0))))^3*(6*(0.5*(1.0-tanh(x/sqrt(2.0))))^2-15*(0.5*(1.0-tanh(x/sqrt(2.0))))+10)+0.1*(1-(0.5*(1.0-tanh(x/sqrt(2.0))))^3*(6*(0.5*(1.0-tanh(x/sqrt(2.0))))^2-15*(0.5*(1.0-tanh(x/sqrt(2.0))))+10))
  [../]
[]

[Materials]
  [./fl]
    type = DerivativeParsedMaterial
    f_name = fl
    args = 'cl cs'
    #function = '(1-cl-cs)*-15188.7188728 + cl*5000 + cs*5000 + 3*cs*cs*-1.44 + 3*cl*cl*2.60 + 3*cl*cs*-3.225
    #            + 8.314*300*((1-cl-cs)*log(1-cl-cs) + cl*log(cl) + cs*log(cs))
    #            + (1-cl-cs)*cl*4.17 + (1-cl-cs)*cs*-1.04 + cl*cs*-3.225'
    function = '(1-cl-cs)*1000 + cl*5000 + cs*1000
                + 0.42857*8.314*300*(2.33*cl*log(2.33*cl) + (1-2.33*cl)*log(1-2.33*cl))'
  [../]

  [./fs]
    type = DerivativeParsedMaterial
    f_name = fs
    args = 'cl cs'
    function = '(1-cl-cs)*-52515.479353 + cl*-75207.7147891 + cs*-30594.038534 + 6*(1-cl-cs)*cs*16.65 + 6*(1-cl-cs)*cl*8.94 + 6*(1-cl-cs)*(1-cl-cs)*-10
                + 0.5*8.314*300*(2*(1-cl-cs)*log(2*(1-cl-cs)) + (1-2*(1-cl-cs))*log(1-2*(1-cl-cs)))
                + (1-cl-cs)*cl*0.51 + (1-cl-cs)*cs*6.76 + cl*cs*16.65'
  [../]

  [./h_eta]
    type = SwitchingFunctionMaterial
    h_order = HIGH
    eta = eta
  [../]

  [./g_eta]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta
  [../]

  [./constants]
    type = GenericConstantMaterial
    prop_names  = 'M   L   eps_sq'
    prop_values = '0.7 0.7 0.1  '    # eps_sq is the gradient energy coefficient.
  [../]
[]

[Kernels]
  [./PhaseConc]
    type = KKSPhaseConcentration
    ca       = cl
    variable = cs
    c        = c
    eta      = eta
  [../]

  [./ChemPotSolute]
    type = KKSPhaseChemicalPotential
    variable = cl
    cb       = cs
    fa_name  = fl
    fb_name  = fs
  [../]

  [./CHBulk]
    type = KKSSplitCHCRes
    variable = c
    ca       = cl
    cb       = cs
    fa_name  = fl
    fb_name  = fs
    w        = w
  [../]

  [./dcdt]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]

  [./ckernel]
    type = SplitCHWRes
    mob_name = M
    variable = w
  [../]

  [./ACBulkF]
    type = KKSACBulkF
    variable = eta
    fa_name  = fl
    fb_name  = fs
    w       = 10.0           # DW height parameter
    args = 'cl cs'
  [../]

  [./ACBulkC]
    type = KKSACBulkC
    variable = eta
    ca       = cl
    cb       = cs
    fa_name  = fl
    fb_name  = fs
  [../]

  [./ACInterface]
    type = ACInterface
    variable = eta
    kappa_name = eps_sq
  [../]

  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
[]

[AuxKernels]
  [./GlobalFreeEnergy]
    variable = Fglobal
    type = KKSGlobalFreeEnergy
    fa_name = fl
    fb_name = fs
    w = 10.0                   # DW height parameter
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'

  petsc_options_iname = '-pc_type -sub_pc_type -sub_pc_factor_shift_type'
  petsc_options_value = 'asm      ilu          nonzero'

  l_max_its = 100
  nl_max_its = 100
  nl_abs_tol = 1e-11

  end_time = 1e7
  #dt = 1
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 8
    iteration_window = 2
    dt = 100.0
  [../]
  [./Predictor]
    type = SimplePredictor
    scale = 0.5
  [../]
[]

#
# Precondition using handcoded off-diagonal terms
#
[Preconditioning]
  [./full]
    type = SMP
    full = true
  [../]
[]

[Postprocessors]
  [./dofs]
    type = NumDOFs
  [../]

  [./F_tot]
      type = ElementIntegralVariablePostprocessor
      variable = Fglobal
  [../]

  [./C]
      type = ElementAverageValue
      variable = c
  [../]
#  [./integral]
#    type = ElementL2Error
#    variable = eta
#    function = ic_func_eta
#  [../]
[]

[Outputs]
  exodus = true
  console = true
  gnuplot = true
[]

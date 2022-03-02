// RUN: mlir-hlo-opt %s -verify-diagnostics -split-input-file -allow-unregistered-dialect | FileCheck %s

// CHECK: func @scatter
func @scatter(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// CHECK: func @scatter_with_unranked_inputs
func @scatter_with_unranked_inputs(%input_tensor: tensor<*xf32>,
    %scatter_indices: tensor<*xi32>, %updates: tensor<*xf32>) ->
      tensor<*xf32> {
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<*xf32>, tensor<*xi32>, tensor<*xf32>) ->
    tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xf32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {
  // expected-error @+1 {{operand #1 must be tensor of integer or index values, but got 'tensor<10x2xf32>'}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xf32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// -----

func @invalid_scatter(%input_tensor: tensor<*xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<*xf32>) ->
      tensor<*xf32> {
  // expected-error @+1 {{expects scatter index leaf dimension to be within [0, rank(scatter_indices) + 1. rank(scatter_indices) is 2 and scatter index leaf dimension is 3.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 3
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<*xf32>, tensor<10x2xi32>, tensor<*xf32>) ->
      tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {
  // expected-error @+1 {{expects scatter index leaf dimension to be within [0, rank(scatter_indices) + 1. rank(scatter_indices) is 2 and scatter index leaf dimension is -1.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = -1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// -----

func @invalid_scatter(%input_tensor: tensor<*xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<*xf32> {
  // expected-error @+1 {{expects updates tensor must be of rank 3 ( == rank-of('scatter_indices') - 1 + size-of('update_window_dims'), where 'scatter_indices' is expanded by a trailing 1 dimension if 'index_vector_dim' == rank-of('scatter_indices')), but got 2.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1, 0],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<*xf32>, tensor<10x2xi32>, tensor<10x300xf32>) -> tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {
  // expected-error @+1 {{expects updates tensor must be of rank 3 ( == rank-of('scatter_indices') - 1 + size-of('update_window_dims'), where 'scatter_indices' is expanded by a trailing 1 dimension if 'index_vector_dim' == rank-of('scatter_indices')), but got 2.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 2
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// -----

func @invalid_scatter_dimensions() ->  tensor<512x1x6400x6400xf32> {
  %base = mhlo.constant dense<0.000000e+00> : tensor<512x1x6400x6400xf32>
  %index = mhlo.constant dense<0> : tensor<1xi32>
  %update = mhlo.constant dense<1.000000e+00> : tensor<512x1x6400x6400xf32>

  // expected-error @+1 {{Expects update_window_dims to be sorted; got: [0, 1, 3, 2].}}
  %scatter = "mhlo.scatter"(%base, %index, %update) ({
    ^bb0(%arg5: tensor<f32>, %arg6: tensor<f32>):
      "mhlo.return"(%arg6) : (tensor<f32>) -> ()
  }) {
    indices_are_sorted = true,
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [0, 1, 3, 2],
      scatter_dims_to_operand_dims = [3]>,
      index_vector_dim = 0,
      unique_indices = true} :
    (tensor<512x1x6400x6400xf32>, tensor<1xi32>, tensor<512x1x6400x6400xf32>) ->
      tensor<512x1x6400x6400xf32>

  return %scatter :  tensor<512x1x6400x6400xf32>
}

// -----

func @invalid_scatter_dimensions() ->  tensor<512x1x6400x6400xf32> {
  %base = mhlo.constant dense<0.000000e+00> : tensor<512x1x6400x6400xf32>
  %index = mhlo.constant dense<0> : tensor<1xi32>
  %update = mhlo.constant dense<1.000000e+00> : tensor<512x1x6400x6400xf32>

  // expected-error @+1 {{Expects update_window_dims to not repeat; got: [0, 1, 2, 2].}}
  %scatter = "mhlo.scatter"(%base, %index, %update) ({
    ^bb0(%arg5: tensor<f32>, %arg6: tensor<f32>):
      "mhlo.return"(%arg6) : (tensor<f32>) -> ()
  }) {
    indices_are_sorted = true,
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [0, 1, 2, 2],
      scatter_dims_to_operand_dims = [3]>,
      index_vector_dim = 0,
      unique_indices = true} :
    (tensor<512x1x6400x6400xf32>, tensor<1xi32>, tensor<512x1x6400x6400xf32>) ->
      tensor<512x1x6400x6400xf32>

  return %scatter :  tensor<512x1x6400x6400xf32>
}

// -----

func @invalid_scatter_dimensions() ->  tensor<512x1x6400x6400xf32> {
  %base = mhlo.constant dense<0.000000e+00> : tensor<512x1x6400x6400xf32>
  %index = mhlo.constant dense<0> : tensor<1xi32>
  %update = mhlo.constant dense<1.000000e+00> : tensor<512x1x6400x6400xf32>

  // expected-error @+1 {{Expects each element of update_window_dims to be in range [0, rank-of('updates') i.e. [0, 4). got: 4.}}
  %scatter = "mhlo.scatter"(%base, %index, %update) ({
    ^bb0(%arg5: tensor<f32>, %arg6: tensor<f32>):
      "mhlo.return"(%arg6) : (tensor<f32>) -> ()
  }) {
    indices_are_sorted = true,
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [0, 1, 2, 4],
      scatter_dims_to_operand_dims = [3]>,
      index_vector_dim = 0,
      unique_indices = true} :
    (tensor<512x1x6400x6400xf32>, tensor<1xi32>, tensor<512x1x6400x6400xf32>) ->
      tensor<512x1x6400x6400xf32>

  return %scatter :  tensor<512x1x6400x6400xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<*xf32>,
    %scatter_indices: tensor<*xi32>, %updates: tensor<*xf32>) ->
      tensor<*xf32> {

  // expected-error @+1 {{Expects inserted_window_dims to be sorted; got: [1, 0].}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [1, 0],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<*xf32>, tensor<*xi32>, tensor<*xf32>) -> tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {
// expected-error @+1 {{Expects inserted_window_dims to not repeat; got: [1, 1].}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [1, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {

  // expected-error @+1 {{Expects each element of inserted_window_dims to be in range [0, rank-of('operand') i.e. [0, 3). got: 3.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 3],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<*xi32>, %updates: tensor<*xf32>) -> tensor<*xf32> {

  // expected-error @+1 {{Expects rank-of operand to match size-of('update_window_dims')  + size-of('inserted_window_dims') i.e. 4 but got 3.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1, 2],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<*xi32>, tensor<*xf32>) -> tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<*xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<*xf32>) ->
      tensor<*xf32> {

  // expected-error @+1 {{Scatter op has 3 elements in scatter_dims_to_operand_dims and the bound of dimension index_vector_dim=1 of scatter_indices is 2. These two numbers must be equal.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1, 2],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<*xf32>, tensor<10x2xi32>, tensor<*xf32>) ->
      tensor<*xf32>
  return %0 : tensor<*xf32>
}

func @valid_scatter_dimensions_with_dynamic_index_vector_dim(
    %input_tensor: tensor<*xf32>, %scatter_indices: tensor<10x?xi32>,
    %updates: tensor<*xf32>) -> tensor<*xf32> {

  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1, 2],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<*xf32>, tensor<10x?xi32>, tensor<*xf32>) -> tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<*xi32>, %updates: tensor<*xf32>) -> tensor<*xf32> {

  // expected-error @+1 {{Invalid scatter_dims_to_operand_dims mapping; domain is [0, 3), got: 1->3.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 3],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<*xi32>, tensor<*xf32>) -> tensor<*xf32>
  return %0 : tensor<*xf32>
}

// -----

func @invalid_scatter_dimensions(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100x300xf32> {

  // expected-error @+1 {{Expects scatter_dims_to_operand_dims to not repeat; got: [0, 0].}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 0],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100x300xf32>
  return %0 : tensor<200x100x300xf32>
}

// -----

func @invalid_scatter_return_type(%input_tensor: tensor<200x100x300xf32>,
    %scatter_indices: tensor<10x2xi32>, %updates: tensor<10x300xf32>) ->
      tensor<200x100xf32> {

  // expected-error @+1 {{expects the return type to be same as the operand type: 'tensor<200x100x300xf32>', but got 'tensor<200x100xf32>'.}}
  %0 = "mhlo.scatter" (%input_tensor, %scatter_indices, %updates) ({
  ^bb0(%lhs: tensor<f32>, %rhs: tensor<f32>):
    %add = mhlo.add %lhs, %rhs : tensor<f32>
    "mhlo.return"(%add) : (tensor<f32>) -> ()
  }) {
    scatter_dimension_numbers = #mhlo.scatter<
      update_window_dims = [1],
      inserted_window_dims = [0, 1],
      scatter_dims_to_operand_dims = [0, 1],
      index_vector_dim = 1
    >,
    indices_are_sorted = true,
    unique_indices = true
  } : (tensor<200x100x300xf32>, tensor<10x2xi32>, tensor<10x300xf32>) ->
      tensor<200x100xf32>
  return %0 : tensor<200x100xf32>
}

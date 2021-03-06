// Copyright 2021-2021 XMOS LIMITED.
// This Software is subject to the terms of the XMOS Public Licence: Version 1.

#if defined(__XS3A__)
#ifndef XS3_MATH_NO_ASM

/*  

  M_rows MUST be a multiple of 16, and N_cols MUST be a multiple of 32

void xs3_mat_mul_s8_x_s8_yield_s32 (
    xs3_split_acc_s32_t accumulators[],
    const int8_t matrix[],
    const int8_t input_vect[],
    const unsigned M_rows,
    const unsigned N_cols);
*/


#include "../asm_helper.h"

#define NSTACKWORDS     (10+8)

#define FUNCTION_NAME   xs3_mat_mul_s8_x_s8_yield_s32

#define STACK_N_COLS    (NSTACKWORDS+1)

#define STACK_VEC_TMP   (NSTACKWORDS-8)

#define STACK_M_ROWS      (9)
#define STACK_INPUT_VECT  (9)

#define accs            r0 
#define matrix          r1 
#define vector          r2
#define rows_left       r3
#define cols_left       r4
#define _32             r5
#define N_cols          r6
#define mat_stride_B    r7
#define mat_stride_C    r8

.text
.issue_mode dual
.align 4

.cc_top FUNCTION_NAME.function,FUNCTION_NAME


//// The first matrix stride is just the number of columns, because we move back (i.e. lower addresses) one row
//// between each VLMACCR

//// The second matrix stride is to move from the end of one input group to the beginning of the next. The delta
//// between two input groups is 32 bytes, and in between N_cols will have been subtracted 15 times. So the second
//// stride ends up being:  mat_stride_B = 15 * N_cols + 32 =  (N_cols << 4) + (32 - N_cols)

//// The third stride is to move from the end of one output group to the beginning of the next.
//// After the final application of mat_stride_B, the matrix pointer will be pointing just AFTER the last element
//// of the last row of the current output group... which is the same as the first element of the next input group.
//// Because of the direction in which the accumulators rotate, we need to start an output group pointing at
//// the beginning of the last row. So:  mat_stride_C = 15 * N_cols

FUNCTION_NAME:
    dualentsp NSTACKWORDS
    ldc r11, 0x200
    std r4, r5, sp[1]
    std r6, r7, sp[2]
    std r8, r9, sp[3]
  { ldc _32, 32                               ; stw r10, sp[1]                            }
  {                                           ; vsetc r11                                 }
  { shr rows_left, rows_left, 4               ; ldw N_cols, sp[STACK_N_COLS]              }
  { shl mat_stride_B, N_cols, 4               ; stw vector, sp[STACK_INPUT_VECT]          }
  { sub mat_stride_C, mat_stride_B, N_cols    ; stw N_cols, sp[STACK_N_COLS]              }
  { add mat_stride_B, mat_stride_C, _32       ;                                           }
  { add matrix, matrix, mat_stride_C          ; bu .L_output_group_top                    }

  .align 16
  .L_output_group_top:
    { add r11, accs, _32                        ; vldd accs[0]                              }
    { mov cols_left, N_cols                     ; vldr r11[0]                               }
    { sub rows_left, rows_left, 1               ; ldw vector, sp[STACK_INPUT_VECT]          }
    
    .L_input_group_top:
      { add vector, vector, _32                   ; vldc vector[0]                            }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub matrix, matrix, N_cols                ; vlmaccr matrix[0]                         }
      { sub cols_left, cols_left, _32             ; vlmaccr matrix[0]                         }
      { add matrix, matrix, mat_stride_B          ; bt cols_left, .L_input_group_top          }
    .L_input_group_bottom:

    { add accs, accs, _32                       ; vstd accs[0]                              }
    { add accs, accs, _32                       ; vstr accs[0]                              }
    { add matrix, matrix, mat_stride_C          ; bt rows_left, .L_output_group_top         }
  .L_output_group_bottom:
    
.L_finish:
      ldd r4, r5, sp[1]
      ldd r6, r7, sp[2]
      ldd r8, r9, sp[3]
  {                                           ; ldw r10, sp[1]                          }
  {                                           ; retsp NSTACKWORDS                       } 

.L_func_end:
.cc_bottom FUNCTION_NAME.function


.global FUNCTION_NAME
.type FUNCTION_NAME,@function
.set FUNCTION_NAME.nstackwords,NSTACKWORDS; .global FUNCTION_NAME.nstackwords
.set FUNCTION_NAME.maxcores,1;              .global FUNCTION_NAME.maxcores
.set FUNCTION_NAME.maxtimers,0;             .global FUNCTION_NAME.maxtimers
.set FUNCTION_NAME.maxchanends,0;           .global FUNCTION_NAME.maxchanends
.size FUNCTION_NAME, .L_func_end - FUNCTION_NAME


#endif //!defined(XS3_MATH_NO_ASM)
#endif //defined(__XS3A__)




#if defined HAVE_CONFIG_H
#include "config.h"
#endif

!==================================================================================================!
! example : serial program with wrapped real matrices in simple dense format                       !
!                                                                                                  !
! This example demonstrates how to calculate:                                                      !
!   alpha = tr(A^T*B)                                                                              !
! for two NxM matrices A and B, in five different ways. Each way should return the same result.    !
! They are:                                                                                        !
!   1. performing the matrix product trace res1 := tr(A^T*B) directly as a single operation        !
!   2. performing the multiplication D := A^T*B, and then the trace res2 := tr(D)                  !
!   3. performing E := B*A^T, and then res3 := tr(E)                                               !
!   4. performing the transpose C := A^T, then D := C*B, and then res4 := tr(D)                    !
!   5. performing C := A^T, then E := B*C, and then res5 := tr(E)                                  !
! Finally, as an extra check, the first element of E is printed out.                               !
!                                                                                                  !
! Note the difference in the code in how matrix B is handled compared with the other matrices.     !
! While the others are allocated directly by MatrixSwitch (i.e., all the data is contained within  !
! the type(matrix) variable), B is a wrapper for MyMatrix (i.e., MyMatrix has been registered as B !
! for use with MatrixSwitch, and B contains a pointer to MyMatrix).                                !
!                                                                                                  !
! Sample output:                                                                                   !
!--------------------------------------------------------------------------------------------------!
! res1 :    31.194861937321843                                                                     !
! res2 :    31.194861937321846                                                                     !
! res3 :    31.194861937321846                                                                     !
! res4 :    31.194861937321846                                                                     !
! res5 :    31.194861937321846                                                                     !
! E_11 :     2.779421970931733                                                                     !
!--------------------------------------------------------------------------------------------------!
!==================================================================================================!
program example_sdden_wrapper
  use MatrixSwitch_wrapper

  implicit none

  !**** PARAMS **********************************!

  integer, parameter :: dp=selected_real_kind(15,300)

  real(dp), parameter :: res_check=31.194861937321846_dp
  real(dp), parameter :: el_check=2.779421970931733_dp

  complex(dp), parameter :: cmplx_1=(1.0_dp,0.0_dp)
  complex(dp), parameter :: cmplx_i=(0.0_dp,1.0_dp)
  complex(dp), parameter :: cmplx_0=(0.0_dp,0.0_dp)

  !**** VARIABLES *******************************!

  character(5) :: m_storage
  character(3) :: m_operation
  character(1), allocatable :: keys(:)

  integer :: num_matrices
  integer :: N, M, i, j

  real(dp) :: rn, res1, res2, res3, res4, res5, el
  real(dp), allocatable :: MyMatrix(:,:)

  !**********************************************!

  m_storage='sdden'
  m_operation='ref' ! try changing to 'lap'

  N=15
  M=8

  num_matrices=5
  allocate(keys(num_matrices))
  keys=(/'A','B','C','D','E'/)
  call ms_wrapper_open(num_matrices,keys)

  call m_allocate('A',N,M,m_storage)

  allocate(MyMatrix(N,M))

  call m_allocate('C',M,N,m_storage)
  call m_allocate('D',M,M,m_storage)
  call m_allocate('E',N,N,m_storage)

  rn=0.1_dp
  do i=1,N
  do j=1,M
    rn=mod(4.2_dp*rn,1.0_dp)
    call m_set_element('A',i,j,rn,0.0_dp)
    rn=mod(4.2_dp*rn,1.0_dp)
    MyMatrix(i,j)=rn
  end do
  end do

  call m_register_sden('B',MyMatrix)

  call mm_trace('A','B',res1,m_operation)

  print('(a,f21.15)'), 'res1 : ', res1
  call assert_equal_dp(res1, res_check)

  call mm_multiply('A','t','B','n','D',1.0_dp,0.0_dp,m_operation)

  call m_trace('D',res2,m_operation)

  print('(a,f21.15)'), 'res2 : ', res2
  call assert_equal_dp(res2, res_check)

  call mm_multiply('B','n','A','t','E',1.0_dp,0.0_dp,m_operation)

  call m_trace('E',res3,m_operation)

  print('(a,f21.15)'), 'res3 : ', res3
  call assert_equal_dp(res3, res_check)

  call m_add('A','t','C',1.0_dp,0.0_dp,m_operation)

  call mm_multiply('C','n','B','n','D',1.0_dp,0.0_dp,m_operation)

  call m_trace('D',res4,m_operation)

  print('(a,f21.15)'), 'res4 : ', res4
  call assert_equal_dp(res4, res_check)

  call m_add('A','t','C',1.0_dp,0.0_dp,m_operation)

  call mm_multiply('B','n','C','n','E',1.0_dp,0.0_dp,m_operation)

  call m_trace('E',res5,m_operation)

  print('(a,f21.15)'), 'res5 : ', res5
  call assert_equal_dp(res5, res_check)

  call m_get_element('E',1,1,el)

  print('(a,f21.15)'), 'E_11 : ', el
  call assert_equal_dp(el, el_check)

  call ms_wrapper_close()

  deallocate(MyMatrix)

  deallocate(keys)

  contains

  subroutine assert_equal_dp(value1, value2)
    implicit none

    !**** PARAMS **********************************!

    real(dp), parameter :: tolerance=1.0d-10

    !**** INPUT ***********************************!

    real(dp), intent(in) :: value1
    real(dp), intent(in) :: value2

    !**********************************************!

    if (abs(value1-value2)>tolerance) stop 1

  end subroutine assert_equal_dp

end program example_sdden_wrapper

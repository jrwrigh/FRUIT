!------------------------
!
! Author: Andrew H. Chen chen@meihome.com
! Last modified: 2004/01/12
! Version : $Revision$
!------------------------
module fruit_utility

  !-------
  ! Assert true 
  !-------
  interface equals
      module procedure equalEpsilon
      module procedure floatEqual
      module procedure integerEqual
      module procedure doublePrecisionEqual
      module procedure stringEqual
      module procedure logicalEqual
  end interface

contains

!------------------
! Compare 2 files
!
! a tool to compare two text files, return 0 is files are the same
! 
! @param file1 input file 1
! @param file2 input file 2
! @return error_code return code
!     0 - success; file 1 and file 2 are the same
!     1 - file 1 not exist
!     2 - file 2 not exist
!     3 - operation error
!     4 - file difference found
!------------------


  
  !------------------------
  ! test if 2 values are close
  !------------------------
  !logical function equals (number1, number2) 
  !  real,  intent (in) :: number1, number2
  !  
  !  return equalEpsilon (number1, number2, epsilon(number1))
  !
  !end function equals

  
  function equalEpsilon (number1, number2, epsilon ) result (resultValue)
    real , intent (in) :: number1, number2, epsilon 
    logical :: resultValue 
    
    resultValue = .false.
    
    ! test very small number1
    if ( abs(number1) < epsilon .and.  abs(number1 - number2) < epsilon ) then
      resultValue = .true.
    else 
      if ((abs(( number1 - number2)) / number1) < epsilon ) then
        resultValue = .true.
      else
        resultValue = .false.
      end if
    end if
    
  end function equalEpsilon

  
  function floatEqual (number1, number2 ) result (resultValue)
    real , intent (in) :: number1, number2
    real :: epsilon 
    logical :: resultValue 
    
    resultValue = .false.
    epsilon = 1E-6
    !epsilon = epsilon (number1)
    
    ! test very small number1
    if ( abs(number1) < epsilon .and.  abs(number1 - number2) < epsilon ) then
      resultValue = .true.
    else 
      if ((abs(( number1 - number2)) / number1) < epsilon ) then
        resultValue = .true.
      else
        resultValue = .false.
      end if
    end if
    
  end function floatEqual

  function doublePrecisionEqual (number1, number2 ) result (resultValue)
    double precision , intent (in) :: number1, number2
    real :: epsilon 
    logical :: resultValue 
    
    resultValue = .false.
    epsilon = 1E-6
    !epsilon = epsilon (number1)
    
    ! test very small number1
    if ( abs(number1) < epsilon .and.  abs(number1 - number2) < epsilon ) then
      resultValue = .true.
    else 
      if ((abs(( number1 - number2)) / number1) < epsilon ) then
        resultValue = .true.
      else
        resultValue = .false.
      end if
    end if
    
  end function doublePrecisionEqual

  function integerEqual (number1, number2 ) result (resultValue)
    integer , intent (in) :: number1, number2
    logical :: resultValue 
    
    resultValue = .false.
    
    if ( number1 .eq. number2 ) then
      resultValue = .true.
    else 
        resultValue = .false.
    end if
    
  end function integerEqual

  function stringEqual (str1, str2 ) result (resultValue)
    character(*) , intent (in) :: str1, str2
    logical :: resultValue 
    
    resultValue = .false.
    
    if ( str1 .eq. str2 ) then
      resultValue = .true.
    end if
    
  end function stringEqual

  function logicalEqual (l1, l2 ) result (resultValue)
    logical, intent (in) :: l1, l2
    logical              :: resultValue 
    
    resultValue = .false.
    
    if ( l1 .eqv. l2 ) then
      resultValue = .true.
    end if
 
  end function logicalEqual

end module fruit_utility

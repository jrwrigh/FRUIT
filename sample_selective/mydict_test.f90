module mydict_test
  use constants
  use mydict
  use fruit
  implicit none
contains
  subroutine test_new_mydict
    type(ty_mydict), pointer :: new_dict

    nullify(new_dict)
    call new_mydict(new_dict)
    call assert_equals(.true., associated(new_dict))
    call assert_equals(.true., associated(new_dict%keys), "keys")
    call assert_equals(.true., associated(new_dict%values), "values")
  end subroutine test_new_mydict

  subroutine test_mydict_add
    type(ty_mydict), pointer :: a_dict

    nullify(a_dict)
    call new_mydict(a_dict)
    call mydict_add(a_dict, "some_key", "some_value")

    call assert_equals("some_key", a_dict%keys(1))
    call assert_equals("some_value", a_dict%values(1))
  end subroutine test_mydict_add
end module mydict_test

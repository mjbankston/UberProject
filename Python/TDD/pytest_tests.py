import funcs_to_test

# pytest uses *only* assert statements


def test1():
    ''' passes '''
    assert funcs_to_test.add(1, 2) == 3


def test2():
    ''' passes '''
    assert funcs_to_test.bad_add(2, 2) == 4


def test3():
    ''' fails '''
    assert funcs_to_test.bad_add(2, 3) == 5

import unittest

# All tests are included in classes that inherit unittest.TestCase


class Test1(unittest.TestCase):

    # Tests must start with the letters 'test' to be included.
    def test_assert_true_passing(self):
        self.assertTrue(True)

    def test_assert_equals_passing(self):
        self.assertEquals(5, 5)

    def test_assert_false_failing(self):
        self.assertFalse(2, 2)


# This block lets the unit tests run and give a report if this script
# is run from the command lines
if __name__ == '__main__':
    unittest.main()

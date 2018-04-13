import unittest
import funcs_to_test

# This file is compatible with nosetests, pytest, and just running pure Python


class Funcs_Test(unittest.TestCase):

    def add_test1(self):
        x = 1
        y = 2
        self.assertEqual(funcs_to_test.add(x, y), 3)


if __name__ == '__main__':
    unittest.main()

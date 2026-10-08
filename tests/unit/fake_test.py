import pytest

@pytest.fixture
def x():
    return 100

@pytest.mark.parametrize(
    "a,b,result",
    [
        (1, 2, 103),
        (3, 4, 107),
        (10, 5, 115),
    ]
)
def test_add(x, a, b, result):
    assert x + a + b == result

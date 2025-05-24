import pytest
from packaging_practice.slow_add import slow_add


@pytest.mark.slow
def test__slow_add():
    """Test the slow_add function."""
    result = slow_add(2, 3)
    assert result == 5, "Expected 2 + 3 to equal 5"
import pytest
from packaging_practice.states_info import is_city_capitol_of_state

@pytest.mark.parametrize(
    "city_name, state, expected",
    [
        ("Montgomery", "Alabama", True),
        ("Juneau", "Alaska", True),
        ("Juneau", "Alabama", False),
        ("Phoenix", "Arizona", True),
        ("Phoenix", "Arkansas", False),
        ("Little Rock", "Arkansas", True),
        ("Little Rock", "Arizona", False),
    ],
)
def test_is_city_capitol_of_state(city_name, state, expected):
    assert is_city_capitol_of_state(city_name, state) == expected


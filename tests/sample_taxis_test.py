import os
import pytest
from demo import taxis

@pytest.mark.skipif(
    os.getenv("CI") == "true",
    reason="Requires live Databricks/Spark; skipped in CI",
)
def test_find_all_taxis():
    results = taxis.find_all_taxis()
    assert results.count() > 5
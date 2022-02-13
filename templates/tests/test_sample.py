# Copyright (C) 2022 by replaceWithAuthorName
r"""Tests for tests. Whee."""

import pytest

from replaceWithPackageName.sample import hi


def test_hi_without_argument():
    r"""plain old 'Hello, World!'"""
    assert hi() == 'Hello, World!'


@pytest.mark.parametrize('target', [
    'olleh',
    'Mom',
    None
])
def test_hi_with_arguments(target):
    r"""different versions of 'Hello, something!'"""

    assert hi(target) == f'Hello, {"World" if target is None else target}!'

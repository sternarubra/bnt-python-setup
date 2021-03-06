# Copyright (C) 2022 by replaceWithAuthorName
r"""Sample functions to ensure that the package is set up correctly."""


def hi(target: str=None) -> str:
    r"""Just another variation on 'hello, world!'

    Parameters
    ----------
    target : str, optional
        The object of the greeting

    Returns
    -------
    str : f"Hello, {target}"

    Examples
    --------
    >>> hi('Mom')
    Hello, Mom!
    >>> hi()
    Hello, World!

    """

    if target is None:
        target = 'World'

    return f'Hello, {target}!'

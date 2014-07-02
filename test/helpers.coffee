define [], ->

    cartesian_power = (sigma, n) ->
        # For a list sigma, constructs the cartesian product sigma^n,
        # assuming n >= 1.
        return ([s] for s in sigma) if n <= 1
        prev_tuples = cartesian_power sigma, n - 1
        out_tuples = []
        (out_tuples.push t.concat [x] for t in prev_tuples) for x in sigma
        out_tuples

    mapping = (list, rule) ->
        # Applies the function rule to each element of list.
        rule(x) for x in list

    {
        cartesian_power : cartesian_power,
        mapping : mapping
    }
def special_form?(exp)
    lambda?(exp) or
        let?(exp) or
        letrec?(exp) or
        if?(exp)
end

def eval_special_form(exp, env)
    if lambda?(exp)
        eval_lambda(exp, env)
    elsif let?(exp)
        eval_let(exp, env)
    elsif letrec?(exp)
        eval_letrec(exp, env)
    elsif if?(exp)
        eval_if(exp, env)
    end
end

def eval_if(exp, env)
    cond, true_caluse, false_clause = if_to_cond_true_false(exp)
    if _eval(cond, env)
        _eval(true_caluse, env)
    else
        _eval(false_clause, env)
    end
end

def if_to_cond_true_false(exp)
    [exp[1], exp[2], exp[3]]
end

def if?(exp)
    exp[0] == :if
end

$boolean_env = 
    {:true => true, :false => false}
$global_env = [$primitive_fun_env, $boolean_env]

$primitive_fun_env = {
    :+   => [:prim, lambda{|x, y| x + y}],
    :-   => [:prim, lambda{|x, y| x - y}],
    :*   => [:prim, lambda{|x, y| x * y}],
    :>   => [:prim, lambda{|x, y| x > y}],
    :>=  => [:prim, lambda{|x, y| x >= y}],
    :<   => [:prim, lambda{|x, y| x < y}],
    :<=  => [:prim, lambda{|x, y| x <= y}],
    :==  => [:prim, lambda{|x, y| x == y}],
}
$global_env = [$primitive_fun_env, $boolean_env]

def eval_letrec(exp, env)
    parameters, args, body = letrec_to_parameters_args_body(exp)
    tmp_env = Hash.new
    parameters.each do |parameter|
        tmp_env[parameter] = :dummy
    end
    ext_env = extend_env(tmp_env.keys(), tmp_env.values(), env)
    args_val = eval_list(args, ext_env)
    set_extend_env!(parameters, args_val, ext_env)
    new_exp = [[:lambda, parameters, body]] + args
    _eval(new_exp, ext_env)
end

def set_extend_env!(parameters, args_val, ext_env)
    parameters.zip(args_val).each do |parameter, arg_val|
        ext_env[0][parameter] = arg_val
    end
end

def letrec_to_parameters_args_body(exp)
    let_to_parameters_args_body(exp)
end

def letrec?(exp)
    exp[0] == :letrec
end

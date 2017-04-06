def null?(list)
    list == []
end

$list_env = {
    :nil  => [],
    :null => [:prim, lambda{|list| null?(list)}],
    :cons => [:prim, lambda{|a, b| cons?(a, b)}],
    :car  => [:prim, lambda{|list| car?(list)}],
    :cdr  => [:prim, lambda{|list| cdr?(list)}],
    :list => [:prim, lambda{|*list| list(*list)}],
}

$glocal_env = [$list_env, $primitive_fun_env, $boolean_env]

def cons(a, b)
    if no list?(b)
        raise "Sorry, we haven't implemented yet..."
    else
        [a] + b
    end
end

def car(list)
    list[0]
end

def cdr(list)
    list[1..-1]
end

def list(*list)
    list
end

def eval_define(exp, env)
    if define_with_parameter?(exp)
        var, val = define_with_parameter_var_val(exp)
    else
        var, val = define_var_val(exp)
    end
    var_ref = lookup_var_ref(var, env)
    if var_ref != nil
        var_ref[var] = _eval(val, env)
    else
        extend_env!([var], [_eval(val, env)], env)
    end
    nil
end

def extend_env!(parameters, args, env)
    alist = parameters.zip(args)
    alist.each { |k, v| h[k] = v}
    env.unshift(h)
end

def define_with_parameter?(exp)
    list?(exp[1])
end

def define_with_parameter_var_val
    var = car(exp[1])
    parameters, body = cdr(exp[1]), exp[2]
    val = [:lambda, parameters, body]
    [var, val]
end

def define_var_val(exp)
    [exp[1], exp[2]]
end

def lookup_var_ref(var, env)
    env.find{|alist| alist.key?(var)}
end

def define?(exp)
    exp[0] == :define
end

def eval_cond(exp, env)
    if_exp = cond_to_if(cdr(exp))
    eval_if(if_exp, env)
end

def cond_to_if(cond_exp)
    if cond_exp == []
        ''
    else
        e = car(cond_exp)
        p, c = e[0], e[1]
        if p == :else
            p = :true
        end
        [:if, p, c, cond_to_if(cdr(cond_exp))]
    end
end

def cond?(exp)
    exp[0] == :cond
end

def parse(exp)
    program = exp.strip().
        gsub(/[a-zA-Z\+\-\*><=][0-9a-zA-Z\+\-=!*]*/, ':\\0').
        gsub(/\s+/, ', ').
        gsub(/\(/, '[').
        gsub(/\)/, ']')
    eval(program)
end

def eval_quote(exp, env)
    car(cdr(exp))
end

def quote?(exp)
    exp[0] == :quote
end

def special_form?(exp)
    lambda?(exp) or
        let?(exp) or
        letrec?(exp) or
        if?(exp) or
        cond?(exp) or
        define?(exp) or
        quote?(exp)
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
    elsif cond?(exp)
        eval_cond(exp, env)
    elsif define?(exp)
        eval_define(exp, env)
    elsif quote?(exp)
        eval_quote(exp, env)
    end
end

def repl
    prompt = '>>> '
    second_prompt = '> '
    while true
        print prompt
        line = gets or return
        while line.count('(') > line.count(')')
            print second_prompt
            next_line = gets or return
            line += next_line
        end
        redo if line =~ /\A\s*\z/m
        begin
            val = _eval(parse(line), $global_env)
        rescue Exception => e
            puts e.to_s
            redo
        end
        puts pp(val)
    end
end

def closure?(exp)
    exp[0] == :closure
end

def pp(exp)
    if exp.is_a?(Symbol) or num?(exp)
        exp.to_s
    elsif exp == nil
        'nil'
    elsif exp.is_a?(Array) and closure?(exp)
        parameter, body, env = exp[1], exp[2], exp[3]
        "(closure #{pp(parameter)} #{pp(body)})"
    elsif exp.is_a?(Hash)
        if exp == $primitive_fun_env
            '*primitive_fun_env*'
        elsif exp == $boolean_env
            '*boolean_env*'
        elsif exp == $list_env
            '*list_env*'
        else
            '{' + exp.map{|k, v| pp(k) + ':' + pp(v)}.join(', ') + '}'
        end
    elsif exp.is_a?(Array)
        '(' + exp.map{|e| pp(e)}.join(', ') + ')'
    else
        exp.to_s
    end
end

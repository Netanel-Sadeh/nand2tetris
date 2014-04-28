require 'rltk'

module Jack

    class Parser < RLTK::Parser

        # a jack compilation unit / class
        p(:class) do
            c('CLASS IDENT LBRACE cvardec* subdec* RBRACE') do |_,klass,_,cvars,subs,_|
                Jack::Class.new(klass, cvars, subs)
            end
        end

        # a class variable declaration
        p(:cvardec, 'cvarscope vartype varnamelist SEMICOLON') do |scope, type, names,_|
            names.map{|e| Jack::ClassVarDec.new(scope, type, e)}
        end

        # a variable declaration
        p(:vardec, 'VAR varlist SEMICOLON')   { |_,vars,_| vars }

        # a class variable scope
        p(:cvarscope) do
            c('STATIC')     { |s| s }
            c('FIELD')      { |s| s }
        end

        # variable type
        p(:vartype) do
            c('INT')        { |t| :int }
            c('CHAR')       { |t| :char }
            c('BOOLEAN')    { |t| :boolean }
            c('IDENT')      { |t| t }
        end

        # a nonempty list of variable names
        nonempty_list(:varnamelist, :IDENT, :COMMA)

        # a subroutine declaration
        p(:subdec) do
            c('subtype rettype IDENT LPAREN varlist RPAREN LBRACE subbody RBRACE') do |klass,rettype,name,_,params,_,_,body,_|
                klass = Module.const_get(klass)
                klass.new(klass, rettype, name, params, body)
            end
        end

        # a subroutine type
        p(:subtype) do
            c('CONSTRUCTOR')    { |_| 'Jack::Constructor' }
            c('FUNCTION')       { |_| 'Jack::Function' }
            c('METHOD')         { |_| 'Jack::Method' }
        end

        # subroutine return type
        p(:rettype) do
            c('VOID')           { |t| :void }
            c('vartype')        { |t| t }
        end

        # a variable declration
        p(:typedvar, 'vartype IDENT')   { |type,name| Jack::VarDec.new(type, name) }

        # a nonempty list of typed variables
        empty_list(:varlist, :typedvar, :COMMA)

        # a subroutine body
        p(:subbody, 'vardec* statements') do |vars,statements|
            Jack::SubBody.new(vars[0], statements)
        end

        # a possibly empty list of statements
        empty_list(:statements, :statement)

        # a jack statement
        p(:statement) do
            c('LET IDENT arrindex? EQUALS expression SEMICOLON') do |_,name,index,_,expr,_|
                Jack::LetStatement.new(Jack::Var.new(name, index), expr)
            end
            c('IF LPAREN expression RPAREN LBRACE statements RBRACE elseclause?') do |_,_,expr,_,_,ifstatements,_,elsestatements|
                Jack::IfStatement.new(expr, ifstatements, elsestatements)
            end
            c('WHILE LPAREN expression RPAREN LBRACE statements RBRACE') do |_,_,expr,_,_,statements,_|
                Jack::WhileStatement.new(expr, statements)
            end
            c('DO subcall SEMICOLON') do |_,subcall,_|
                Jack::DoStatement.new(subcall)
            end
            c('RETURN expression? SEMICOLON') do |_,expr,_|
                Jack::ReturnStatement.new(expr)
            end
        end

        # a subroutine call
        p(:subcall, 'prefix? IDENT LPAREN expressionlist RPAREN') do |prefix,name,_,exprlist,_|
            Jack::SubCall.new(prefix, name, exprlist)
        end

        # the else clause to an if statement
        p(:elseclause, 'ELSE LBRACE statements RBRACE') do |_,_,statements,_|
            statements
        end

        # an index to an array var
        p(:arrindex, 'LBRACKET expression RBRACKET') do |_, expr, _|
            Jack::Expression.new expr
        end

        # a prefix
        p(:prefix, 'IDENT DOT')    { |prefix,_| prefix }

        # a jack expression
        nonempty_list(:expr, [ :term, :op ])
        p(:expression, 'expr') { |e| Jack::Expression.new e }

        # an expression term
        p(:term) do
            c('INTEGER')            { |t| t }
            c('STRING')             { |t| t }
            c('const')              { |t| t }
            c('IDENT arrindex?')    { |name,index| Jack::Var.new(name, index) }
            c('subcall')            { |t| t }
            c('LPAREN expression RPAREN')   { |_,expr,_| expr }
            c('unaryop term')       { |op,t| Jack::UnaryOp.new(op, term) }
        end

        # an expression operator
        p(:op) do
            c('PLUS')           { |t| t }
            c('MINUS')          { |t| t }
            c('MULT')           { |t| t }
            c('DIV')            { |t| t }
            c('AND')            { |t| t }
            c('OR')             { |t| t }
            c('LT')             { |t| t }
            c('GT')             { |t| t }
            c('EQUALS')         { |t| t }
        end

        # a unary operation
        p(:unaryop) do
            c('MINUS')              { |t| t }
            c('NEG')                { |t| t }
        end

        # a constant
        p(:const) do
            c('TRUE')   { |c| c }
            c('FALSE')  { |c| c }
            c('NULL')   { |c| c }
            c('THIS')   { |c| c }
        end

        # a nonempty list of expressions
        empty_list(:expressionlist, :expression, :COMMA)

        finalize :explain => ENV.key?('DUMP_PARSER')

    end

end

scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Use menos palavras, evite frases comuns"
      "Não são necessários símbolos, números ou letras maiúsculas"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Adicione 1 ou 2 palavras. Palavras incomuns são melhores.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Letras seguidas no teclado são fáceis de descobrir'
        else
          'Padrões curtos de teclado são fáceis de descobrir'
        warning: warning
        suggestions: [
          'Use um padrão de teclado com mais letras e não seguidos'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Repetições como "aaa" são fáceis de descobrir'
        else
          'Repetições como "abcabcabc" são quase tão fáceis de descobrir quanto "abc"'
        warning: warning
        suggestions: [
          'Evite palavras ou letras repetidas'
        ]

      when 'sequence'
        warning: "Sequências como 'abc' ou '6543'  são fáceis de descobrir"
        suggestions: [
          'Evite sequências'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Anos recentes são fáceis de descobrir"
          suggestions: [
            'Evite anos recentes'
            'Evite anos recentes relacionados a você'
          ]

      when 'date'
        warning: "Datas  são fáceis de descobrir"
        suggestions: [
          'Evite datas e anos relacionados a você'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Esta é umas das 10 senhas mais comuns'
        else if match.rank <= 100
          'Esta é umas das 100 senhas mais comuns'
        else
          'Esta é senha comum'
      else if match.guesses_log10 <= 4
        'Esta senha é muito parecida com uma das senhas mais comuns'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'Uma única palavra é muito fáceil de descobrir'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Nomes e sobrenomes sozinhos são fáceis de descobrir'
      else
        'Nomes e sobrenomes comuns são fáceis de descobrir'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Letras maiúsculas não ajudam muito"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Todas Letras maiúsculas são tão fáceis quanto todas minúsculas"

    if match.reversed and match.token.length >= 4
      suggestions.push "Palavras invertidas são fáceis de descobrir"
    if match.l33t
      suggestions.push "Subsituições comuns como '@' no lugar do 'a' não ajudam muito"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback

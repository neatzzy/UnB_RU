module FastpassHelper
  # Mensagem do painel de resultado (US14). Inscrição ainda "inscrito" depois do
  # horário de divulgação quer dizer que o sorteio ainda não rodou.
  def mensagem_do_resultado(inscricao)
    case inscricao.status
    when "contemplado" then "Você ganhou o FastPass!"
    when "nao_contemplado" then "Você não ganhou o FastPass. Boa sorte na próxima vez."
    else "O resultado do sorteio ainda está sendo processado. Volte em instantes."
    end
  end
end

module Estudante
  # Sorteio do FastPass: o aluno escolhe uma janela por turno (US13) e vê o
  # resultado a partir de 1 hora antes do turno (US14).
  class FastpassController < BaseController
    def show
      @turnos = TipoRefeicao.where(id: TimeFrame.select(:tipo_refeicao_id))
                            .order(:hora_inicio).includes(:time_frames)
      @inscricoes = current_user.inscricoes_fastpass.where(data: Date.current)
                                .includes(time_frame: :tipo_refeicao)
                                .index_by { |inscricao| inscricao.time_frame.tipo_refeicao_id }
      # Na ordem dos turnos, só as inscrições cujo resultado já foi divulgado.
      @resultados = @turnos.filter_map { |turno| @inscricoes[turno.id] }.select(&:resultado_liberado?)
    end
  end
end

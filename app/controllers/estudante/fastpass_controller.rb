module Estudante
  # Sorteio do FastPass (US13): o aluno escolhe uma janela por turno.
  class FastpassController < BaseController
    before_action :exigir_aluno

    def show
      @turnos = TipoRefeicao.where(id: TimeFrame.select(:tipo_refeicao_id))
                            .order(:hora_inicio).includes(:time_frames)
      inscricoes = current_user.inscricoes_fastpass.where(data: Date.current)
                               .includes(time_frame: :tipo_refeicao).to_a
      @inscricoes = inscricoes.index_by { |inscricao| inscricao.time_frame.tipo_refeicao_id }
      avisar_inscricao_duplicada(inscricoes)
    end

    private

    # A página mostra uma inscrição por turno. Se a corrida documentada em InscricaoFastpass
    # criar duas no mesmo turno, uma fica escondida; o log deixa isso visível para o admin.
    def avisar_inscricao_duplicada(inscricoes)
      return if inscricoes.size == @inscricoes.size

      Rails.logger.warn("FastPass: aluno #{current_user.id} tem mais de uma inscrição no mesmo turno em #{Date.current}")
    end
  end
end

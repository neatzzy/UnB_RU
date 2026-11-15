# Inscrição de um aluno no sorteio do FastPass em uma janela (time-frame) de um turno.
class InscricaoFastpass < ApplicationRecord
  self.table_name = "inscricoes_fastpass"

  # Resultado do sorteio: preenchido pela #14 e conferido na catraca pela #15.
  enum :status, { inscrito: "inscrito", contemplado: "contemplado", nao_contemplado: "nao_contemplado" },
       default: :inscrito

  belongs_to :aluno, class_name: "User", inverse_of: :inscricoes_fastpass
  belongs_to :time_frame
  # Opcionais desde a #13: a inscrição é feita por janela, sem depender do cardápio do dia.
  belongs_to :restaurante, optional: true
  belongs_to :refeicao, optional: true

  validates :data, presence: true
  # Regra do ER original, para quando refeicao_id voltar a ser preenchido. No fluxo
  # da #13 a coluna fica nula, e o índice (aluno_id, refeicao_id) não barra nada:
  # quem garante a unicidade hoje é uma_por_turno_no_dia.
  validates :aluno_id, uniqueness: { scope: :refeicao_id }, if: :refeicao_id?
  validate :uma_por_turno_no_dia, if: -> { aluno && time_frame && data }

  # O resultado do sorteio sai 1 hora antes do início do turno (US14).
  ANTECEDENCIA_DO_RESULTADO = 1.hour

  # Início do turno no dia da inscrição. A coluna hora_inicio guarda só o horário
  # (com a data 2000-01-01), por isso a hora e o minuto são aplicados sobre a data.
  def inicio_do_turno
    hora = time_frame.tipo_refeicao.hora_inicio
    data.in_time_zone.change(hour: hora.hour, min: hora.min)
  end

  def resultado_liberado?
    Time.current >= inicio_do_turno - ANTECEDENCIA_DO_RESULTADO
  end

  # O aluno só cancela antes do sorteio e antes de o resultado ser divulgado.
  # A view e o controller usam a mesma regra.
  def cancelavel?
    inscrito? && !resultado_liberado?
  end

  private

  # A regra é uma inscrição por turno (Almoço, Jantar) no dia, e não por janela.
  # O banco só garante a mesma janela (índice aluno_id, data, time_frame_id): dois
  # envios simultâneos em janelas diferentes do mesmo turno ainda passariam.
  def uma_por_turno_no_dia
    turno = time_frame.tipo_refeicao
    outras = InscricaoFastpass.joins(:time_frame)
                              .where(aluno: aluno, data: data, time_frames: { tipo_refeicao_id: turno.id })
                              .where.not(id: id)

    errors.add(:base, :ja_inscrito_no_turno, turno: turno.nome) if outras.exists?
  end
end

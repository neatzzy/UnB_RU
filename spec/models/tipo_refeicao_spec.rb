require "rails_helper"

RSpec.describe TipoRefeicao, type: :model do
  let!(:cafe) { TipoRefeicao.create!(nome: "Café da manhã", hora_inicio: "07:00", hora_fim: "09:30") }
  let!(:almoco) { TipoRefeicao.create!(nome: "Almoço", hora_inicio: "11:00", hora_fim: "14:30") }
  let!(:jantar) { TipoRefeicao.create!(nome: "Jantar", hora_inicio: "17:00", hora_fim: "19:30") }

  describe ".vigente_em" do
    it "retorna Café da manhã durante o horário matutino" do
      expect(described_class.vigente_em(Time.zone.parse("2026-11-16 08:15:00"))).to eq(cafe)
    end

    it "retorna Almoço nos limites exatos de início e fim" do
      expect(described_class.vigente_em(Time.zone.parse("2026-11-16 11:00:00"))).to eq(almoco)
      expect(described_class.vigente_em(Time.zone.parse("2026-11-16 14:30:00"))).to eq(almoco)
    end

    it "retorna Jantar durante o turno noturno" do
      expect(described_class.vigente_em(Time.zone.parse("2026-11-16 18:00:00"))).to eq(jantar)
    end

    it "retorna nil fora dos horários de refeição" do
      expect(described_class.vigente_em(Time.zone.parse("2026-11-16 15:45:00"))).to be_nil
    end
  end
end

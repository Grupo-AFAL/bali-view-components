# frozen_string_literal: true

module Bali
  # #709 — cuánta de la audiencia de un registro ya firmó:
  #
  #   coverage = Bali::ReadCoverage.new(@document, audience: @document.readers)
  #   coverage.coverage_percentage # => 75.0
  #   coverage.pending_users       # => [#<User ...>]
  #   coverage.below_threshold?    # => true
  #
  # La audiencia se INYECTA y el engine no opina de dónde sale. En
  # gobierno-corporativo se arma con Workday::Worker, departamentos y readers; nada de eso
  # es trasplantable ni tiene por qué estarlo. Lo único que se les pide a los usuarios es
  # que respondan `id` y tengan clase, para casar con el par polimórfico de la firma.
  #
  # Tampoco agrupa por área: eso es del host, que es quien sabe qué es un área.
  class ReadCoverage
    # El 80 es el único valor que existe en producción hoy (COMPLIANCE_THRESHOLD de
    # gobierno-corporativo), pero vive aquí como default y no como constante compartida:
    # el umbral es una política de cada app.
    DEFAULT_THRESHOLD = 80

    attr_reader :record, :audience, :threshold

    def initialize(record, audience:, threshold: DEFAULT_THRESHOLD)
      @record = record
      @audience = audience.to_a
      @threshold = threshold
    end

    def total_count = audience.size

    def confirmed_count = confirmed_users.size

    def pending_count = pending_users.size

    def confirmed_users = partitioned_audience.first

    def pending_users = partitioned_audience.last

    # nil, NO 0, cuando no hay audiencia (decisión 709-4). Un registro que nadie tiene que
    # leer no está cubierto al 0% — su cobertura sencillamente no está definida, y 0/0 no
    # es cero. Devolver 0.0 pinta de rojo un tablero por documentos que no le tocan a
    # nadie, y devolver 100.0 afirma una cobertura que nadie confirmó; nil obliga a quien
    # renderiza a decidir qué escribe ahí ("—", "Sin audiencia"), que es la única salida
    # honesta. `below_threshold?` sigue respondiendo un booleano, así que el camino de
    # cumplimiento no se rompe.
    def coverage_percentage
      return nil if total_count.zero?

      (confirmed_count * 100.0 / total_count).round(1)
    end

    # Sin audiencia no hay incumplimiento: no hay nadie pendiente. Aquí también se separa
    # de gobierno-corporativo, que devuelve `true` y marca como incumplido todo registro
    # sin lectores asignados.
    def below_threshold?
      return false if total_count.zero?

      coverage_percentage < threshold
    end

    private

    # Una sola consulta y un solo recorrido: `pluck` del par polimórfico a un Set y
    # partition en memoria. La audiencia ya viene materializada, así que iterarla es
    # gratis comparado con preguntar por cada usuario.
    def partitioned_audience
      @partitioned_audience ||= audience.partition { |user| confirmed_keys.include?(key_for(user)) }
    end

    def confirmed_keys
      @confirmed_keys ||= record.acknowledgments.pluck(:user_type, :user_id).to_set
    end

    # `polymorphic_name` y no `class.name` para que una jerarquía STI case con lo que la
    # firma guardó (que es la clase base).
    def key_for(user)
      [ user.class.polymorphic_name, user.id ]
    end
  end
end

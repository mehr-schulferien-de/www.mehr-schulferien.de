defmodule MehrSchulferien.Repo.Migrations.RemoveHtmlClassColumns do
  use Ecto.Migration

  def up do
    # Remove html_class from periods table
    alter table(:periods) do
      remove :html_class
    end

    # Remove default_html_class from holiday_or_vacation_types table
    alter table(:holiday_or_vacation_types) do
      remove :default_html_class
    end
  end

  def down do
    # Re-add html_class to periods table
    alter table(:periods) do
      add :html_class, :string
    end

    # Re-add default_html_class to holiday_or_vacation_types table
    alter table(:holiday_or_vacation_types) do
      add :default_html_class, :string
    end

    # Restore default values for holiday_or_vacation_types
    execute """
    UPDATE holiday_or_vacation_types
    SET default_html_class = CASE
      WHEN default_is_school_vacation = true THEN 'success'
      WHEN default_is_public_holiday = true THEN 'danger'
      WHEN name = 'Wochenende' THEN 'active'
      WHEN name = 'Beweglicher Ferientag' THEN 'success'
      ELSE NULL
    END;
    """

    # Restore html_class values for periods based on their type
    execute """
    UPDATE periods p
    SET html_class = COALESCE(
      h.default_html_class,
      CASE
        WHEN p.is_school_vacation = true THEN 'success'
        WHEN p.is_public_holiday = true THEN 'danger'
        ELSE NULL
      END
    )
    FROM holiday_or_vacation_types h
    WHERE p.holiday_or_vacation_type_id = h.id;
    """
  end
end

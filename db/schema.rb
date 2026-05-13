# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_13_134119) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alternatives", force: :cascade do |t|
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_alternatives_on_question_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "category", limit: 100, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "image_path", limit: 500
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lessons", force: :cascade do |t|
    t.text "content_editor"
    t.datetime "created_at", null: false
    t.string "file_path", limit: 500
    t.string "file_type", limit: 10
    t.bigint "module_id", null: false
    t.string "name", null: false
    t.integer "order_num", null: false
    t.datetime "updated_at", null: false
    t.index ["module_id", "order_num"], name: "index_lessons_on_module_id_and_order_num"
    t.index ["module_id"], name: "index_lessons_on_module_id"
  end

  create_table "modules", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.string "image_path", limit: 500
    t.string "name", limit: 50, null: false
    t.integer "order_num", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "order_num"], name: "index_modules_on_course_id_and_order_num"
    t.index ["course_id"], name: "index_modules_on_course_id"
  end

  create_table "questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_num", null: false
    t.integer "points", default: 1, null: false
    t.bigint "quiz_id", null: false
    t.text "statement", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id", "order_num"], name: "index_questions_on_quiz_id_and_order_num"
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "module_id", null: false
    t.boolean "show_correct_answers", default: false, null: false
    t.boolean "show_points", default: false, null: false
    t.boolean "show_wrong_answers", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["module_id"], name: "index_quizzes_on_module_id", unique: true
  end

  add_foreign_key "alternatives", "questions", on_delete: :cascade
  add_foreign_key "lessons", "modules", on_delete: :cascade
  add_foreign_key "modules", "courses", on_delete: :cascade
  add_foreign_key "questions", "quizzes", on_delete: :cascade
  add_foreign_key "quizzes", "modules", on_delete: :cascade
end


export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "dossiers": {
                  Row: {
                    "briefing_summary": string,"category": string,"content_markdown": string,"created_at": string,"id": string,"is_code_related": boolean,"required_clearance": number,"slug": string,"title": string
                  }
                  Insert: {
                    "briefing_summary": string,"category": string,"content_markdown": string,"created_at"?: string,"id"?: string,"is_code_related"?: boolean,"required_clearance"?: number,"slug": string,"title": string
                  }
                  Update: {
                    "briefing_summary"?: string,"category"?: string,"content_markdown"?: string,"created_at"?: string,"id"?: string,"is_code_related"?: boolean,"required_clearance"?: number,"slug"?: string,"title"?: string
                  }
                  Relationships: [
                    
                  ]
                },"field_tests": {
                  Row: {
                    "created_at": string,"dossier_id": string,"id": string,"passing_criteria": NonNullable<Json>,"scenario_description": string,"test_type": string
                  }
                  Insert: {
                    "created_at"?: string,"dossier_id": string,"id"?: string,"passing_criteria"?: NonNullable<Json>,"scenario_description": string,"test_type": string
                  }
                  Update: {
                    "created_at"?: string,"dossier_id"?: string,"id"?: string,"passing_criteria"?: NonNullable<Json>,"scenario_description"?: string,"test_type"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "field_tests_dossier_id_fkey"
      columns: ["dossier_id"]
isOneToOne: false
      referencedRelation: "dossiers"
      referencedColumns: ["id"]
    }
                  ]
                },"user_progress": {
                  Row: {
                    "completed_at": string | null,"created_at": string,"dossier_id": string,"id": string,"status": string,"user_id": string
                  }
                  Insert: {
                    "completed_at"?: string | null,"created_at"?: string,"dossier_id": string,"id"?: string,"status"?: string,"user_id": string
                  }
                  Update: {
                    "completed_at"?: string | null,"created_at"?: string,"dossier_id"?: string,"id"?: string,"status"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "user_progress_dossier_id_fkey"
      columns: ["dossier_id"]
isOneToOne: false
      referencedRelation: "dossiers"
      referencedColumns: ["id"]
    },{
      foreignKeyName: "user_progress_user_id_fkey"
      columns: ["user_id"]
isOneToOne: false
      referencedRelation: "users"
      referencedColumns: ["id"]
    }
                  ]
                },"users": {
                  Row: {
                    "clearance_level": number,"created_at": string,"email": string,"id": string,"intel_points": number,"selected_topics": (string)[],"topic_clearances": NonNullable<Json>
                  }
                  Insert: {
                    "clearance_level"?: number,"created_at"?: string,"email": string,"id": string,"intel_points"?: number,"selected_topics"?: (string)[],"topic_clearances"?: NonNullable<Json>
                  }
                  Update: {
                    "clearance_level"?: number,"created_at"?: string,"email"?: string,"id"?: string,"intel_points"?: number,"selected_topics"?: (string)[],"topic_clearances"?: NonNullable<Json>
                  }
                  Relationships: [
                    
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "get_dossier_catalog":
{ Args: Record<PropertyKey, never>; Returns: {
              "briefing_summary": string,"category": string,"field_test_id": string,"has_field_test": boolean,"id": string,"is_code_related": boolean,"required_clearance": number,"slug": string,"title": string
            }[]
                           },
"get_field_test":
{ Args: { "p_test_id": string }; Returns: Json
                           },
"submit_field_test":
{ Args: { "p_answer": string,"p_test_id": string,"p_user_id"?: string }; Returns: Json
                           },
"update_user_interests":
{ Args: { "p_selected_topics": (string)[] }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            
          }
        }
} as const


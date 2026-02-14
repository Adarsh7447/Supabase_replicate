DROP TRIGGER IF EXISTS trg_unified_agents_update_timestamp ON public.new_unified_agents;
CREATE TRIGGER trg_unified_agents_update_timestamp
    BEFORE UPDATE ON public.new_unified_agents
    FOR EACH ROW
    EXECUTE FUNCTION update_last_updated_column();
    